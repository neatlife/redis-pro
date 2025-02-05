//
//  StringEditView.swift
//  redis-pro
//
//  Created by chengpanwang on 2021/4/7.
//

import SwiftUI
import Logging
import ComposableArchitecture

struct StringEditorView: View {
    var store: Store<StringValueState, StringValueAction>
    private let logger = Logger(label: "string-editor")
    
    var body: some View {
        WithViewStore(store) {viewStore in
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: MTheme.V_SPACING){
                    // text editor
                    MTextEditor(text: viewStore.binding(\.$text))
                }
                .background(Color.init(NSColor.textBackgroundColor))
                
                // footer
                HStack(alignment: .center, spacing: MTheme.H_SPACING) {
                    if (viewStore.isIntactString) {
                        Text("lenth: \(viewStore.length)")
                    } else {
                        Text("range: 0~\(viewStore.stringMaxLength + 1) / \(viewStore.length)")
                        MButton(text: "Show Intact", action: {viewStore.send(.getIntactString)})
                    }
                
                    Spacer()
                    MButton(text: "Pretty Json", action: {viewStore.send(.jsonFormat)})
                    IconButton(icon: "arrow.clockwise", name: "Refresh", action: {viewStore.send(.refresh)})
                    IconButton(icon: "checkmark", name: "Submit", disabled: !viewStore.isIntactString, action: {viewStore.send(.submit)})
                }
                .padding(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                
            }
            
            .onAppear {
                logger.info("redis string value editor view appear ...")
            }
        }
    }
    
}

//struct StringEditView_Previews: PreviewProvider {
//    static var redisKeyModel:RedisKeyModel = RedisKeyModel(key: "tes", type: "string")
//    static var previews: some View {
//        StringEditorView(redisKeyModel: redisKeyModel)
//    }
//}
