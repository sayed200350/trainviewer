import Foundation
import CoreLocation

public struct University: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let city: String
    public let state: String
    public let latitude: Double?
    public let longitude: Double?
    public let website: String?
    public let brandColor: String?

    public var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    public init(id: String, name: String, city: String, state: String,
                latitude: Double? = nil, longitude: Double? = nil,
                website: String? = nil, brandColor: String? = nil) {
        self.id = id
        self.name = name
        self.city = city
        self.state = state
        self.latitude = latitude
        self.longitude = longitude
        self.website = website
        self.brandColor = brandColor
    }
}

// MARK: - German Universities Data
extension University {
    public static let germanUniversities: [University] = [
        // Baden-Württemberg
        University(id: "uni-freiburg", name: "Universität Freiburg", city: "Freiburg", state: "Baden-Württemberg",
                  latitude: 47.9948, longitude: 7.8499, website: "uni-freiburg.de", brandColor: "#005CA9"),
        University(id: "uni-heidelberg", name: "Universität Heidelberg", city: "Heidelberg", state: "Baden-Württemberg",
                  latitude: 49.4094, longitude: 8.6947, website: "uni-heidelberg.de", brandColor: "#003366"),
        University(id: "uni-stuttgart", name: "Universität Stuttgart", city: "Stuttgart", state: "Baden-Württemberg",
                  latitude: 48.7819, longitude: 9.1733, website: "uni-stuttgart.de", brandColor: "#E3000F"),
        University(id: "kit-karlsruhe", name: "Karlsruher Institut für Technologie", city: "Karlsruhe", state: "Baden-Württemberg",
                  latitude: 49.0144, longitude: 8.4044, website: "kit.edu", brandColor: "#0083CC"),
        University(id: "uni-tuebingen", name: "Universität Tübingen", city: "Tübingen", state: "Baden-Württemberg",
                  latitude: 48.5216, longitude: 9.0576, website: "uni-tuebingen.de", brandColor: "#004B87"),
        University(id: "uni-ulm", name: "Universität Ulm", city: "Ulm", state: "Baden-Württemberg",
                  latitude: 48.4196, longitude: 9.9572, website: "uni-ulm.de", brandColor: "#0099CC"),
        University(id: "uni-mannheim", name: "Universität Mannheim", city: "Mannheim", state: "Baden-Württemberg",
                  latitude: 49.4875, longitude: 8.4661, website: "uni-mannheim.de", brandColor: "#004B87"),

        // Bavaria (Bayern)
        University(id: "lmu-muenchen", name: "Ludwig-Maximilians-Universität München", city: "München", state: "Bayern",
                  latitude: 48.1508, longitude: 11.5802, website: "lmu.de", brandColor: "#0066CC"),
        University(id: "tum-muenchen", name: "Technische Universität München", city: "München", state: "Bayern",
                  latitude: 48.1494, longitude: 11.5677, website: "tum.de", brandColor: "#3070B3"),
        University(id: "uni-wuerzburg", name: "Universität Würzburg", city: "Würzburg", state: "Bayern",
                  latitude: 49.7892, longitude: 9.9531, website: "uni-wuerzburg.de", brandColor: "#004B87"),
        University(id: "uni-erlangen", name: "Friedrich-Alexander-Universität Erlangen-Nürnberg", city: "Erlangen", state: "Bayern",
                  latitude: 49.5761, longitude: 11.0281, website: "fau.de", brandColor: "#003366"),
        University(id: "uni-regensburg", name: "Universität Regensburg", city: "Regensburg", state: "Bayern",
                  latitude: 49.0139, longitude: 12.1016, website: "uni-regensburg.de", brandColor: "#004B87"),
        University(id: "uni-augsburg", name: "Universität Augsburg", city: "Augsburg", state: "Bayern",
                  latitude: 48.3339, longitude: 10.8977, website: "uni-augsburg.de", brandColor: "#0099CC"),

        // Berlin
        University(id: "hu-berlin", name: "Humboldt-Universität zu Berlin", city: "Berlin", state: "Berlin",
                  latitude: 52.5186, longitude: 13.3936, website: "hu-berlin.de", brandColor: "#0066CC"),
        University(id: "fu-berlin", name: "Freie Universität Berlin", city: "Berlin", state: "Berlin",
                  latitude: 52.4526, longitude: 13.2896, website: "fu-berlin.de", brandColor: "#0099CC"),
        University(id: "tu-berlin", name: "Technische Universität Berlin", city: "Berlin", state: "Berlin",
                  latitude: 52.5125, longitude: 13.3267, website: "tu-berlin.de", brandColor: "#CC0000"),
        University(id: "uni-berlin", name: "Universität Berlin", city: "Berlin", state: "Berlin",
                  latitude: 52.5200, longitude: 13.3936, website: "berlin.de", brandColor: "#004B87"),

        // Brandenburg
        University(id: "uni-potsdam", name: "Universität Potsdam", city: "Potsdam", state: "Brandenburg",
                  latitude: 52.4009, longitude: 13.0125, website: "uni-potsdam.de", brandColor: "#004B87"),

        // Bremen
        University(id: "uni-bremen", name: "Universität Bremen", city: "Bremen", state: "Bremen",
                  latitude: 53.1075, longitude: 8.8494, website: "uni-bremen.de", brandColor: "#0099CC"),

        // Hamburg
        University(id: "uni-hamburg", name: "Universität Hamburg", city: "Hamburg", state: "Hamburg",
                  latitude: 53.5669, longitude: 9.9842, website: "uni-hamburg.de", brandColor: "#004B87"),
        University(id: "tu-hamburg", name: "Technische Universität Hamburg", city: "Hamburg", state: "Hamburg",
                  latitude: 53.4578, longitude: 9.9675, website: "tuhh.de", brandColor: "#CC0000"),

        // Hesse (Hessen)
        University(id: "uni-frankfurt", name: "Goethe-Universität Frankfurt", city: "Frankfurt", state: "Hessen",
                  latitude: 50.1269, longitude: 8.6917, website: "uni-frankfurt.de", brandColor: "#0066CC"),
        University(id: "tu-darmstadt", name: "Technische Universität Darmstadt", city: "Darmstadt", state: "Hessen",
                  latitude: 49.8769, longitude: 8.6547, website: "tu-darmstadt.de", brandColor: "#005CA9"),
        University(id: "uni-kassel", name: "Universität Kassel", city: "Kassel", state: "Hessen",
                  latitude: 51.3186, longitude: 9.4942, website: "uni-kassel.de", brandColor: "#004B87"),
        University(id: "uni-marburg", name: "Philipps-Universität Marburg", city: "Marburg", state: "Hessen",
                  latitude: 50.8111, longitude: 8.7744, website: "uni-marburg.de", brandColor: "#003366"),

        // Lower Saxony (Niedersachsen)
        University(id: "uni-goettingen", name: "Georg-August-Universität Göttingen", city: "Göttingen", state: "Niedersachsen",
                  latitude: 51.5413, longitude: 9.9158, website: "uni-goettingen.de", brandColor: "#004B87"),
        University(id: "tu-braunschweig", name: "Technische Universität Braunschweig", city: "Braunschweig", state: "Niedersachsen",
                  latitude: 52.2692, longitude: 10.5267, website: "tu-braunschweig.de", brandColor: "#0099CC"),
        University(id: "uni-hannover", name: "Leibniz Universität Hannover", city: "Hannover", state: "Niedersachsen",
                  latitude: 52.3819, longitude: 9.7167, website: "uni-hannover.de", brandColor: "#0066CC"),
        University(id: "uni-oldenburg", name: "Carl von Ossietzky Universität Oldenburg", city: "Oldenburg", state: "Niedersachsen",
                  latitude: 53.1472, longitude: 8.1911, website: "uni-oldenburg.de", brandColor: "#004B87"),

        // North Rhine-Westphalia (Nordrhein-Westfalen)
        University(id: "uni-koeln", name: "Universität zu Köln", city: "Köln", state: "Nordrhein-Westfalen",
                  latitude: 50.9288, longitude: 6.9392, website: "uni-koeln.de", brandColor: "#004B87"),
        University(id: "uni-bonn", name: "Rheinische Friedrich-Wilhelms-Universität Bonn", city: "Bonn", state: "Nordrhein-Westfalen",
                  latitude: 50.7356, longitude: 7.1022, website: "uni-bonn.de", brandColor: "#0099CC"),
        University(id: "uni-duesseldorf", name: "Heinrich-Heine-Universität Düsseldorf", city: "Düsseldorf", state: "Nordrhein-Westfalen",
                  latitude: 51.1886, longitude: 6.7939, website: "uni-duesseldorf.de", brandColor: "#004B87"),
        University(id: "tu-dortmund", name: "Technische Universität Dortmund", city: "Dortmund", state: "Nordrhein-Westfalen",
                  latitude: 51.4925, longitude: 7.4211, website: "tu-dortmund.de", brandColor: "#CC0000"),
        University(id: "uni-bochum", name: "Ruhr-Universität Bochum", city: "Bochum", state: "Nordrhein-Westfalen",
                  latitude: 51.4456, longitude: 7.2611, website: "ruhr-uni-bochum.de", brandColor: "#0099CC"),
        University(id: "uni-muenster", name: "Westfälische Wilhelms-Universität Münster", city: "Münster", state: "Nordrhein-Westfalen",
                  latitude: 51.9636, longitude: 7.6139, website: "uni-muenster.de", brandColor: "#004B87"),
        University(id: "uni-siegen", name: "Universität Siegen", city: "Siegen", state: "Nordrhein-Westfalen",
                  latitude: 50.9211, longitude: 8.0211, website: "uni-siegen.de", brandColor: "#0066CC"),
        University(id: "uni-paderborn", name: "Universität Paderborn", city: "Paderborn", state: "Nordrhein-Westfalen",
                  latitude: 51.7086, longitude: 8.7686, website: "uni-paderborn.de", brandColor: "#004B87"),

        // Rhineland-Palatinate (Rheinland-Pfalz)
        University(id: "uni-mainz", name: "Johannes Gutenberg-Universität Mainz", city: "Mainz", state: "Rheinland-Pfalz",
                  latitude: 49.9929, longitude: 8.2472, website: "uni-mainz.de", brandColor: "#004B87"),
        University(id: "uni-trier", name: "Universität Trier", city: "Trier", state: "Rheinland-Pfalz",
                  latitude: 49.7494, longitude: 6.6875, website: "uni-trier.de", brandColor: "#0099CC"),
        University(id: "uni-koblenz", name: "Universität Koblenz-Landau", city: "Koblenz", state: "Rheinland-Pfalz",
                  latitude: 50.3533, longitude: 7.5894, website: "uni-koblenz-landau.de", brandColor: "#004B87"),

        // Saxony (Sachsen)
        University(id: "tu-dresden", name: "Technische Universität Dresden", city: "Dresden", state: "Sachsen",
                  latitude: 51.0272, longitude: 13.7267, website: "tu-dresden.de", brandColor: "#CC0000"),
        University(id: "uni-leipzig", name: "Universität Leipzig", city: "Leipzig", state: "Sachsen",
                  latitude: 51.3397, longitude: 12.3711, website: "uni-leipzig.de", brandColor: "#004B87"),

        // Saxony-Anhalt (Sachsen-Anhalt)
        University(id: "uni-halle", name: "Martin-Luther-Universität Halle-Wittenberg", city: "Halle", state: "Sachsen-Anhalt",
                  latitude: 51.4858, longitude: 11.9678, website: "uni-halle.de", brandColor: "#004B87"),
        University(id: "uni-magdeburg", name: "Otto-von-Guericke-Universität Magdeburg", city: "Magdeburg", state: "Sachsen-Anhalt",
                  latitude: 52.1375, longitude: 11.6417, website: "ovgu.de", brandColor: "#0099CC"),

        // Schleswig-Holstein
        University(id: "uni-kiel", name: "Christian-Albrechts-Universität zu Kiel", city: "Kiel", state: "Schleswig-Holstein",
                  latitude: 54.3233, longitude: 10.1394, website: "uni-kiel.de", brandColor: "#004B87"),
        University(id: "uni-luebeck", name: "Universität zu Lübeck", city: "Lübeck", state: "Schleswig-Holstein",
                  latitude: 53.8356, longitude: 10.7000, website: "uni-luebeck.de", brandColor: "#0099CC"),

        // Thuringia (Thüringen)
        University(id: "uni-jena", name: "Friedrich-Schiller-Universität Jena", city: "Jena", state: "Thüringen",
                  latitude: 50.9286, longitude: 11.5875, website: "uni-jena.de", brandColor: "#004B87"),
        University(id: "tu-ilmenau", name: "Technische Universität Ilmenau", city: "Ilmenau", state: "Thüringen",
                  latitude: 50.6839, longitude: 10.9300, website: "tu-ilmenau.de", brandColor: "#CC0000")
    ]

    // Search functionality
    public static func searchUniversities(query: String) -> [University] {
        guard !query.isEmpty else { return germanUniversities }

        let lowercaseQuery = query.lowercased()
        return germanUniversities.filter { university in
            university.name.lowercased().contains(lowercaseQuery) ||
            university.city.lowercased().contains(lowercaseQuery) ||
            university.state.lowercased().contains(lowercaseQuery)
        }
    }

    // Get universities by state
    public static func universitiesByState(_ state: String) -> [University] {
        return germanUniversities.filter { $0.state == state }
    }

    // Get university by ID
    public static func universityById(_ id: String) -> University? {
        return germanUniversities.first { $0.id == id }
    }
}
