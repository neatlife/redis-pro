//
//  RedisSystemView.swift
//  redis-pro
//
//  Created by chengpan on 2022/6/4.
//

import SwiftUI
import Logging
import ComposableArchitecture

struct RedisSystemView: View {
    var store:Store<RedisSystemState, RedisSystemAction>
    
    var body: some View {
        WithViewStore(store){ viewStore in
            if viewStore.systemView == RedisSystemViewTypeEnum.REDIS_INFO {
                RedisInfoView(store: store.scope(state: \.redisInfoState, action: RedisSystemAction.redisInfoAction))
            }  else if viewStore.systemView == RedisSystemViewTypeEnum.CLIENT_LIST {
                ClientsListView(store: store.scope(state: \.clientListState, action: RedisSystemAction.clientListAction))
            } else if viewStore.systemView == RedisSystemViewTypeEnum.SLOW_LOG {
                SlowLogView(store: store.scope(state: \.slowLogState, action: RedisSystemAction.slowLogAction))
            } else if viewStore.systemView == RedisSystemViewTypeEnum.REDIS_CONFIG {
                RedisConfigView(store: store.scope(state: \.redisConfigState, action: RedisSystemAction.redisConfigAction))
            } else {
                EmptyView()
            }
        }
    }
}

//struct RedisSystemView_Previews: PreviewProvider {
//    static var previews: some View {
//        RedisSystemView()
//    }
//}
