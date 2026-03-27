//
//  SupabaseModels.swift
//  journalcalendar
//
//  Codable DTOs that map directly to Supabase table columns.
//  Conversion extensions bridge between these DTOs and the app's
//  Block/SubBlock types.
//

import Foundation

// MARK: - Block DTO

/// Maps to the `blocks` table.
struct BlockDTO: Codable {
    let id: UUID
    let userId: UUID?
    let title: String
    let date: String        // yyyy-MM-dd
    let startTime: String   // ISO8601 timestamptz
    let endTime: String     // ISO8601 timestamptz

    enum CodingKeys: String, CodingKey {
        case id, title, date
        case userId = "user_id"
        case startTime = "start_time"
        case endTime = "end_time"
    }
}

// MARK: - SubBlock DTO

/// The JSONB `data` payload for a sub-block row. Only fields relevant
/// to the sub-block's `type` will be non-nil.
struct SubBlockDataJSON: Codable {
    var text: String?
    var imagePaths: [String]?
    var url: String?
    var name: String?
    var latitude: Double?
    var longitude: Double?

    enum CodingKeys: String, CodingKey {
        case text, url, name, latitude, longitude
        case imagePaths = "image_paths"
    }
}

/// Maps to the `sub_blocks` table.
struct SubBlockDTO: Codable {
    let id: UUID
    let blockId: UUID
    let type: String
    let data: SubBlockDataJSON
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, type, data
        case blockId = "block_id"
        case sortOrder = "sort_order"
    }
}

// MARK: - Joined Query DTO

/// Used when fetching blocks with their sub-blocks via
/// `.select("*, sub_blocks(*)")`.
struct BlockWithSubBlocksDTO: Codable {
    let id: UUID
    let userId: UUID?
    let title: String
    let date: String
    let startTime: String
    let endTime: String
    let subBlocks: [SubBlockDTO]

    enum CodingKeys: String, CodingKey {
        case id, title, date
        case userId = "user_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case subBlocks = "sub_blocks"
    }
}

// MARK: - Date Formatters

extension BlockDTO {
    /// Formatter for the date-only column (yyyy-MM-dd).
    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f
    }()

    /// Formatter for timestamptz columns (ISO8601).
    static let iso8601Formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}

// MARK: - Block ↔ DTO Conversions

extension Block {
    /// Convert a Block to a BlockDTO for inserting/updating in Supabase.
    func toDTO() -> BlockDTO {
        BlockDTO(
            id: id,
            userId: nil,
            title: title,
            date: BlockDTO.dateFormatter.string(from: date),
            startTime: BlockDTO.iso8601Formatter.string(from: startTime),
            endTime: BlockDTO.iso8601Formatter.string(from: endTime)
        )
    }

    /// Build a Block from a joined query DTO and pre-built SubBlocks.
    init?(dto: BlockWithSubBlocksDTO, subBlocks: [SubBlock]) {
        guard let date = BlockDTO.dateFormatter.date(from: dto.date),
              let startTime = BlockDTO.iso8601Formatter.date(from: dto.startTime),
              let endTime = BlockDTO.iso8601Formatter.date(from: dto.endTime) else {
            return nil
        }
        self.init(
            id: dto.id,
            date: date,
            startTime: startTime,
            endTime: endTime,
            title: dto.title,
            subBlocks: subBlocks
        )
    }
}

// MARK: - SubBlock ↔ DTO Conversions

extension SubBlock {
    /// Convert a SubBlock to a SubBlockDTO. For images, pass the
    /// storage paths obtained after uploading.
    func toDTO(blockId: UUID, sortOrder: Int, imagePaths: [String] = []) -> SubBlockDTO {
        let typeString: String
        let dataJSON: SubBlockDataJSON

        switch self {
        case .journal(_, let text):
            typeString = "journal"
            dataJSON = SubBlockDataJSON(text: text)
        case .images:
            typeString = "images"
            dataJSON = SubBlockDataJSON(imagePaths: imagePaths)
        case .link(_, let url):
            typeString = "link"
            dataJSON = SubBlockDataJSON(url: url)
        case .location(_, let name, let lat, let lng):
            typeString = "location"
            dataJSON = SubBlockDataJSON(name: name, latitude: lat, longitude: lng)
        }

        return SubBlockDTO(
            id: id,
            blockId: blockId,
            type: typeString,
            data: dataJSON,
            sortOrder: sortOrder
        )
    }

    /// Build a SubBlock from a DTO. For images, provide the downloaded
    /// image data separately.
    init(dto: SubBlockDTO, imageData: [Data] = []) {
        switch dto.type {
        case "journal":
            self = .journal(id: dto.id, text: dto.data.text ?? "")
        case "images":
            self = .images(id: dto.id, imageData: imageData)
        case "link":
            self = .link(id: dto.id, url: dto.data.url ?? "")
        case "location":
            self = .location(
                id: dto.id,
                name: dto.data.name ?? "",
                latitude: dto.data.latitude ?? 0,
                longitude: dto.data.longitude ?? 0
            )
        default:
            self = .journal(id: dto.id, text: "")
        }
    }
}
