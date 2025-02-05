//
//  RedisClientKeys.swift
//  redis-pro
//
//  Created by chengpan on 2022/3/6.
//

import Foundation
import RediStack
import Logging

// MARK: - keys function
extension RediStackClient {
    
    private func keyScan(cursor:Int, keywords:String?, count:Int? = 1) async throws -> (cursor:Int, keys:[String]) {
        logger.debug("redis keys scan, cursor: \(cursor), keywords: \(String(describing: keywords)), count:\(String(describing: count))")
        
        let command:RedisCommand<(Int, [RedisKey])> = .scan(startingFrom: cursor, matching: keywords, count: count)
        let r = try await _send(command)
        return (r.0, r.1.map { $0.rawValue })
    }
    
    
    private func countScan(cursor:Int, keywords:String?, count:Int? = 1) async throws -> (cursor:Int, count:Int) {
        logger.debug("redis keys scan, cursor: \(cursor), keywords: \(String(describing: keywords)), count:\(String(describing: count))")
        
        
        let res = try await keyScan(cursor: cursor, keywords: keywords, count: count)
        return (res.0, res.1.count)
    }
    
    
    private func keysCountScan(_ keywords:String?) async throws -> Int {
        if isMatchAll(keywords ?? "") {
            logger.info("keywords is match all, use dbsize...")
            return await dbsize()
        }
        
        var cursor:Int = 0
        var count:Int = 0
        
        while true {
            let res = try await countScan(cursor: cursor, keywords: keywords, count: dataCountScanCount)
            logger.info("loop scan page, current cursor: \(cursor), total count: \(count)")
            cursor = res.0
            count = count + res.1
            
            // 取到结果，或者已满足分页数据
            if cursor == 0{
                break
            }
        }
        return count
    }
    
    private func keysPageScan(_ page: Page) async throws -> [String] {
        let keywords = page.keywords.isEmpty ? nil : page.keywords
        var end:Int = page.end
        var cursor:Int = 0
        var keys:[String] = []
        
        while true {
            let res = try await keyScan(cursor: cursor, keywords: keywords, count: dataScanCount)
            logger.info("loop scan page, current cursor: \(cursor), total count: \(keys.count)")
            cursor = res.0
            keys = keys + res.1
            
            // 取到结果，或者已满足分页数据
            if cursor == 0 || keys.count >= end {
                break
            }
        }
        
        let start = page.start
        if start >= keys.count {
            return []
        }
        
        end = min(end, keys.count)
        return Array(keys[start..<end])
        
    }
    
    func pageKeys(_ page:Page) async -> [RedisKeyModel] {
        begin()
        
        let stopwatch = Stopwatch.createStarted()
        
        logger.info("redis keys page scan, page: \(page)")
        
        let isScan = isScan(page.keywords)
//        let match = page.keywords.isEmpty ? nil : page.keywords
        
        defer {
            self.logger.info("keys scan complete, spend: \(stopwatch.elapsedMillis()) ms")
            complete()
        }
        
        do {
            // 带有占位符的情况，使用
            if isScan {

                let pageData:[String] = try await keysPageScan(page)
             
                return await self.toRedisKeyModels(pageData)
            } else {
                let exist = await self.exist(page.keywords)
                if exist {
                    return await self.toRedisKeyModels([page.keywords])
                } else {
                    return []
                }
            }
            
        } catch {
            self.logger.error("get key type error: \(error)")
            self.handleError(error)
        }

        return []
    }
    
    
    func countKey(_ page:Page, cursor: Int) async -> (Int, Int) {
        // 如果是匹配所，使用dbsize
        if isMatchAll(page.keywords) {
            return (0, await dbsize())
        }
        
        let isScan = isScan(page.keywords)
        let match = page.keywords.isEmpty ? nil : page.keywords
        
        do {
            if isScan {
                let res = try await countScan(cursor: cursor, keywords: match, count: dataCountScanCount)
                logger.info("count scan keys, current cursor: \(cursor), r: \(res)")
                
                return res
            } else {
                let count = await self.exist(page.keywords) ? 1 : 0
                return (0, count)
            }
        } catch {
            handleError(error)
        }
        
        return (0, 0)
    }
    
    func toRedisKeyModels(_ keys:[String]) async -> [RedisKeyModel] {
        if keys.isEmpty {
            return []
        }
        
        var redisKeyModels = [RedisKeyModel]()
        
        let typeDict = await getTypes(keys)
        
        for key in keys {
            redisKeyModels.append(RedisKeyModel(key, type: typeDict[key] ?? RedisKeyTypeEnum.NONE.rawValue))
        }
        
        return redisKeyModels
    }
    
}
