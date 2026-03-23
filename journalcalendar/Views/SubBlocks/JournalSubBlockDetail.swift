//
//  JournalSubBlockDetail.swift
//  journalcalendar
//
//  Created by Elissa Martial on 3/23/26.
//

import SwiftUI

struct JournalSubBlockDetail: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("JOURNAL")
                .labelStyle()
            
            Text(text)
                .font(.body)
                .lineSpacing(4)
        }
    }
}
