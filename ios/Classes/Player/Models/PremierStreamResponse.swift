// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let premierStreamResponse = try PremierStreamResponse(json)

//
// To read values from URLs:
//
//   let task = URLSession.shared.premierStreamResponseTask(with: url) { premierStreamResponse, response, error in
//     if let premierStreamResponse = premierStreamResponse {
//       ...
//     }
//   }
//   task.resume()

import Foundation

// MARK: - PremierStreamResponse
struct PremierStreamResponse: Codable {
    let fileInfo: [FileInfo]

    enum CodingKeys: String, CodingKey {
        case fileInfo = "file_info"
    }
}

// MARK: PremierStreamResponse convenience initializers and mutators

extension PremierStreamResponse {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(PremierStreamResponse.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        fileInfo: [FileInfo]? = nil
    ) -> PremierStreamResponse {
        return PremierStreamResponse(
            fileInfo: fileInfo ?? self.fileInfo
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

//
// To read values from URLs:
//
//   let task = URLSession.shared.fileInfoTask(with: url) { fileInfo, response, error in
//     if let fileInfo = fileInfo {
//       ...
//     }
//   }
//   task.resume()

// MARK: - FileInfo
struct FileInfo: Codable {
    let quality: String
    let fileName: String
    let duration, width, height: Int

    enum CodingKeys: String, CodingKey {
        case quality
        case fileName = "file_name"
        case duration, width, height
    }
}

// MARK: FileInfo convenience initializers and mutators

extension FileInfo {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(FileInfo.self, from: data)
    }

    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }

    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }

    func with(
        quality: String? = nil,
        fileName: String? = nil,
        duration: Int? = nil,
        width: Int? = nil,
        height: Int? = nil
    ) -> FileInfo {
        return FileInfo(
            quality: quality ?? self.quality,
            fileName: fileName ?? self.fileName,
            duration: duration ?? self.duration,
            width: width ?? self.width,
            height: height ?? self.height
        )
    }

    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }

    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: - URLSession response handlers

extension URLSession {
    fileprivate func codableTask<T: Codable>(with url: URL, completionHandler: @escaping (T?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return self.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completionHandler(nil, response, error)
                return
            }
            completionHandler(try? newJSONDecoder().decode(T.self, from: data), response, nil)
        }
    }

    func premierStreamResponseTask(with url: URL, completionHandler: @escaping (PremierStreamResponse?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return self.codableTask(with: url, completionHandler: completionHandler)
    }
}
