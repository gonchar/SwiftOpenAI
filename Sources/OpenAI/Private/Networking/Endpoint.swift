//
//  Endpoint.swift
//
//
//  Created by James Rochabrun on 10/11/23.
//

import Foundation

// MARK: HTTPMethod

enum HTTPMethod: String {
   case post = "POST"
   case get = "GET"
   case delete = "DELETE"
}

// MARK: Endpoint

protocol Endpoint {
  func path(version: String, proxyPath: String?) -> String
}

// MARK: Endpoint+Requests

extension Endpoint {

   private func urlComponents(
      base: String,
      version:String,
      proxyPath: String?,
      queryItems: [URLQueryItem])
      -> URLComponents
   {
      var components = URLComponents(string: base)!
      components.path = path(version: version, proxyPath: proxyPath)
      if !queryItems.isEmpty {
         components.queryItems = queryItems
      }
      return components
   }
   
   func request(
      apiKey: Authorization,
      base: String,
      version: String,
      proxyPath: String?,
      organizationID: String?,
      method: HTTPMethod,
      params: Encodable? = nil,
      queryItems: [URLQueryItem] = [],
      betaHeaderField: String? = nil,
      extraHeaders: [String: String]? = nil)
      throws -> URLRequest
   {
      var request = URLRequest(url: urlComponents(base: base, version: version, proxyPath: proxyPath, queryItems: queryItems).url!)
      request.addValue("application/json", forHTTPHeaderField: "Content-Type")
      request.addValue(apiKey.value, forHTTPHeaderField: apiKey.headerField)
      if let organizationID {
         request.addValue(organizationID, forHTTPHeaderField: "OpenAI-Organization")
      }
      if let betaHeaderField {
         request.addValue(betaHeaderField, forHTTPHeaderField: "OpenAI-Beta")
      }
      if let extraHeaders {
         for header in extraHeaders {
            request.addValue(header.value, forHTTPHeaderField: header.key)
         }
      }
      request.httpMethod = method.rawValue
      if let params {
         request.httpBody = try JSONEncoder().encode(params)
      }
      return request
   }
   
   func multiPartRequest(
      apiKey: Authorization,
      base: String,
      version: String,
      proxyPath: String?,
      organizationID: String?,
      method: HTTPMethod,
      params: MultipartFormDataParameters,
      queryItems: [URLQueryItem] = [])
      throws -> URLRequest
   {
      var request = URLRequest(url: URL(string: urlComponents(base: base, version: version, proxyPath: proxyPath, queryItems: queryItems).path)!)
      request.httpMethod = method.rawValue
      let boundary = UUID().uuidString
      request.addValue(apiKey.value, forHTTPHeaderField: apiKey.headerField)
      if let organizationID {
         request.addValue(organizationID, forHTTPHeaderField: "OpenAI-Organization")
      }
      request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
      request.httpBody = params.encode(boundary: boundary)
      return request
   }
}
