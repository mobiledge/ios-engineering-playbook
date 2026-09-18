import Foundation
import CoreData
import Domain

/// The low-level Core Data stack: a programmatic model + CRUD on the store,
/// translating between `NSManagedObject` and the domain's `SavedItem`.
///
/// It is `internal` and a shared singleton so that every `CoreDataLibraryRepository`
/// instance talks to the same store. (Injecting a single instance app-wide is the
/// job of the Composition Root in Chapter 6.)
final class CoreDataStack {
    static let shared = CoreDataStack()

    private static let entityName = "SavedItemEntity"
    private let container: NSPersistentContainer
    private let logger: Logger = ConsoleLogger()
    private var context: NSManagedObjectContext { container.viewContext }

    private init() {
        let model = CoreDataStack.makeModel()
        container = NSPersistentContainer(name: "iTunesSearchApp", managedObjectModel: model)
        container.loadPersistentStores { [logger] _, error in
            if let error {
                logger.log("Core Data failed to load store: \(error)")
            }
        }
    }

    private static func makeModel() -> NSManagedObjectModel {
        func attribute(_ name: String, _ type: NSAttributeType, optional: Bool = false) -> NSAttributeDescription {
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = optional
            return attribute
        }

        let entity = NSEntityDescription()
        entity.name = entityName
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        entity.properties = [
            attribute("id", .integer64AttributeType),
            attribute("title", .stringAttributeType),
            attribute("subtitle", .stringAttributeType, optional: true),
            attribute("artworkURL", .stringAttributeType, optional: true),
            attribute("mediaType", .stringAttributeType),
            attribute("savedAt", .dateAttributeType)
        ]

        let model = NSManagedObjectModel()
        model.entities = [entity]
        return model
    }

    // MARK: - CRUD (in domain terms)

    func save(_ item: SavedItem) {
        guard !isSaved(id: item.id, mediaType: item.mediaType) else { return }
        guard let entity = container.managedObjectModel.entitiesByName[Self.entityName] else { return }

        let object = NSManagedObject(entity: entity, insertInto: context)
        object.setValue(Int64(item.id), forKey: "id")
        object.setValue(item.title, forKey: "title")
        object.setValue(item.subtitle, forKey: "subtitle")
        object.setValue(item.artworkURL?.absoluteString, forKey: "artworkURL")
        object.setValue(item.mediaType.rawValue, forKey: "mediaType")
        object.setValue(item.savedAt, forKey: "savedAt")
        saveContext()
    }

    func remove(id: Int, mediaType: MediaType) {
        let request = fetchRequest(id: id, mediaType: mediaType)
        if let results = try? context.fetch(request) {
            results.forEach(context.delete)
            saveContext()
        }
    }

    func isSaved(id: Int, mediaType: MediaType) -> Bool {
        let request = fetchRequest(id: id, mediaType: mediaType)
        request.fetchLimit = 1
        return ((try? context.count(for: request)) ?? 0) > 0
    }

    func fetchAll() -> [SavedItem] {
        let request = NSFetchRequest<NSManagedObject>(entityName: Self.entityName)
        request.sortDescriptors = [NSSortDescriptor(key: "savedAt", ascending: false)]
        let objects = (try? context.fetch(request)) ?? []
        return objects.map { object in
            SavedItem(
                id: Int(object.value(forKey: "id") as? Int64 ?? 0),
                title: object.value(forKey: "title") as? String ?? "",
                subtitle: object.value(forKey: "subtitle") as? String,
                artworkURL: (object.value(forKey: "artworkURL") as? String).flatMap(URL.init(string:)),
                mediaType: MediaType(rawValue: object.value(forKey: "mediaType") as? String ?? "") ?? .music,
                savedAt: object.value(forKey: "savedAt") as? Date ?? Date()
            )
        }
    }

    // MARK: - Helpers

    private func fetchRequest(id: Int, mediaType: MediaType) -> NSFetchRequest<NSManagedObject> {
        let request = NSFetchRequest<NSManagedObject>(entityName: Self.entityName)
        request.predicate = NSPredicate(format: "id == %lld AND mediaType == %@", Int64(id), mediaType.rawValue)
        return request
    }

    private func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            logger.log("Core Data save error: \(error)")
        }
    }
}
