//
//  ClientListStore.swift
//  redis-pro
//
//  Created by chengpan on 2022/6/5.
//

import Logging
import Foundation
import SwiftyJSON
import ComposableArchitecture

private let logger = Logger(label: "client-list-store")
struct ClientListState: Equatable {
    
    var tableState: TableState = TableState(
        columns: [
            .init(title: "id", key: "id", width: 60),
            .init(title: "name", key: "name", width: 60),
            .init(title: "addr", key: "addr", width: 140),
            .init(title: "laddr", key: "laddr", width: 140),
            .init(title: "fd", key: "fd", width: 60),
            .init(title: "age", key: "age", width: 60),
            .init(title: "idle", key: "idle", width: 60),
            .init(title: "flags", key: "flags", width: 60),
            .init(title: "db", key: "db", width: 60),
            .init(title: "sub", key: "sub", width: 60),
            .init(title: "psub", key: "psub", width: 60),
            .init(title: "multi", key: "multi", width: 60),
            .init(title: "qbuf", key: "qbuf", width: 60),
            .init(title: "qbuf_free", key: "qbuf_free", width: 60),
            .init(title: "obl", key: "obl", width: 60),
            .init(title: "oll", key: "oll", width: 60),
            .init(title: "omem", key: "omem", width: 60),
            .init(title: "events", key: "events", width: 60),
            .init(title: "cmd", key: "cmd", width: 100),
            .init(title: "argv_mem", key: "argv_mem", width: 60),
            .init(title: "tot_mem", key: "tot_mem", width: 60),
            .init(title: "redir", key: "redir", width: 60),
            .init(title: "user", key: "user", width: 60)
        ]
        , datasource: []
        , contextMenus: [.KILL]
        , selectIndex: -1)
    
    init() {
        logger.info("client list state init ...")
    }
}

enum ClientListAction: Equatable {
    case initial
    case getValue
    case setValue([ClientModel])
    case refresh
    case killConfirm(Int)
    case kill(Int)
    case tableAction(TableAction)
}

struct ClientListEnvironment {
    var redisInstanceModel:RedisInstanceModel
}

let clientListReducer = Reducer<ClientListState, ClientListAction, SystemEnvironment<ClientListEnvironment>>.combine(
    tableReducer.pullback(
        state: \.tableState,
        action: /ClientListAction.tableAction,
        environment: { _ in .init() }
    ),
    Reducer<ClientListState, ClientListAction, SystemEnvironment<ClientListEnvironment>> {
        state, action, env in
        switch action {
        // 初始化已设置的值
        case .initial:
        
            logger.info("client list store initial...")
            return .result {
                .success(.getValue)
            }
        
        case .getValue:
            return .task {
                let r = await env.redisInstanceModel.getClient().clientList()
                return .setValue(r)
            }
            .receive(on: env.mainQueue)
            .eraseToEffect()
        
        case let .setValue(clientLists):
            state.tableState.datasource = clientLists
            
            return .none
            
        case let .killConfirm(index):

            let item = state.tableState.datasource[index] as! ClientModel
            return .future { callback in
                Messages.confirm("Kill Client?"
                                 , message: "Are you sure you want to kill client:\(item.addr)? This operation cannot be undone."
                                  , primaryButton: "Kill"
                                  , action: {
                    callback(.success(.kill(index)))
                })
            }
            
        case let .kill(index):
            let client = state.tableState.datasource[index] as! ClientModel
            logger.info("kill client, addr: \(client.addr)")
            
            return .task {
                let r = await env.redisInstanceModel.getClient().clientKill(client)
                logger.info("do kill client, addr: \(client.addr), r:\(r)")
                
                return .refresh
            }
            .receive(on: env.mainQueue)
            .eraseToEffect()
        
        case .refresh:
            return .result {
                .success(.getValue)
            }
            
        // table action
        case let .tableAction(.contextMenu(title, index)):
            if title == "Kill" {
                return .result {
                    .success(.killConfirm(index))
                }
            }
            
            return .none
        case .tableAction:
            return .none
        }
    }
).debug()
