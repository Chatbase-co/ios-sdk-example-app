//
//  PaginatedResponse.swift
//  tatbeeqMa7mool
//
//  Created by Eesabase on 29/03/2026.
//

import Foundation

struct PaginatedResponse<T> {
    let data: [T]
    let pagination: Pagination
}

struct Pagination {
    let cursor: String?
    let hasMore: Bool
    let total: Int
}
