//
//  LinkSubBlockDetail.swift
//  journalcalendar
//
//  Created by Elissa Martial on 3/23/26.
//

import SwiftUI

struct LinkSubBlockDetail: View {
    let url: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LINK")
                .labelStyle()
            
            if let linkURL = URL(string: url) {
                Link(destination: linkURL) {
                    HStack {
                        Image(systemName: "link")
                            .font(.paragraph1)
                        Text(url)
                            .font(.paragraph1)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .foregroundStyle(.blue)
                }
            } else {
                Text(url)
                    .font(.paragraph1)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
