//
//  CompanyDetailDTO+Mapping.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/24.
//

import Foundation

// MARK: - CompanyDetailDTO Mapping

extension CompanyDetailDTO {

    func mapped() -> Company {
        Company(
            id: id,
            name: name ?? "",
            description: description,
            headquarters: headquarters,
            homepage: homepage.flatMap(URL.init(string:)),
            logoPath: logoPath,
            originCountry: originCountry,
            parentCompany: parentCompany?.mapped()
        )
    }
}

// MARK: - CompanyReferenceDTO Mapping

extension CompanyReferenceDTO {

    func mapped() -> CompanyReference {
        CompanyReference(
            id: id,
            name: name ?? "",
            logoPath: logoPath
        )
    }
}

// MARK: - CompanyAlternativeNamesResponseDTO Mapping

extension CompanyAlternativeNamesResponseDTO {

    func mapped() -> [CompanyAlternativeName] {
        results.compactMap { $0.mapped() }
    }
}

// MARK: - CompanyAlternativeNameDTO Mapping

extension CompanyAlternativeNameDTO {

    func mapped() -> CompanyAlternativeName? {
        guard let name, !name.isEmpty else { return nil }
        return CompanyAlternativeName(name: name, type: type)
    }
}

// MARK: - CompanyImagesDTO Mapping

extension CompanyImagesDTO {

    func mapped() -> CompanyImages {
        CompanyImages(
            id: id,
            logos: logos.compactMap { $0.mapped() }
        )
    }
}

// MARK: - CompanyLogoDTO Mapping

extension CompanyLogoDTO {

    func mapped() -> CompanyLogo? {
        guard let filePath, !filePath.isEmpty else { return nil }
        return CompanyLogo(
            filePath: filePath,
            aspectRatio: aspectRatio ?? 1,
            width: width ?? 0,
            height: height ?? 0,
            voteAverage: voteAverage ?? 0,
            voteCount: voteCount ?? 0
        )
    }
}
