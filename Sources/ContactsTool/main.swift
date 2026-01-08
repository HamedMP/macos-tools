import Contacts
import Foundation

let store = CNContactStore()

func requestAccess() async -> Bool {
    return await withCheckedContinuation { continuation in
        store.requestAccess(for: .contacts) { granted, _ in
            continuation.resume(returning: granted)
        }
    }
}

func searchContacts(query: String, limit: Int = 20) {
    let keysToFetch: [CNKeyDescriptor] = [
        CNContactGivenNameKey as CNKeyDescriptor,
        CNContactFamilyNameKey as CNKeyDescriptor,
        CNContactOrganizationNameKey as CNKeyDescriptor,
        CNContactJobTitleKey as CNKeyDescriptor,
        CNContactEmailAddressesKey as CNKeyDescriptor,
        CNContactPhoneNumbersKey as CNKeyDescriptor
    ]

    let predicate = CNContact.predicateForContacts(matchingName: query)

    do {
        let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)

        if contacts.isEmpty {
            print("No contacts found matching '\(query)'")
            return
        }

        print("Contacts matching '\(query)'")
        print(String(repeating: "-", count: 50))

        for contact in contacts.prefix(limit) {
            let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
            print("\(name)")

            if !contact.organizationName.isEmpty {
                let title = contact.jobTitle.isEmpty ? "" : "\(contact.jobTitle), "
                print("  \(title)\(contact.organizationName)")
            }

            for email in contact.emailAddresses.prefix(2) {
                print("  \(email.value as String)")
            }

            for phone in contact.phoneNumbers.prefix(2) {
                print("  \(phone.value.stringValue)")
            }

            print()
        }
    } catch {
        print("Error searching contacts: \(error.localizedDescription)")
    }
}

func listRecentContacts(limit: Int = 20) {
    let keysToFetch: [CNKeyDescriptor] = [
        CNContactGivenNameKey as CNKeyDescriptor,
        CNContactFamilyNameKey as CNKeyDescriptor,
        CNContactOrganizationNameKey as CNKeyDescriptor
    ]

    let request = CNContactFetchRequest(keysToFetch: keysToFetch)
    var contacts: [CNContact] = []

    do {
        try store.enumerateContacts(with: request) { contact, _ in
            contacts.append(contact)
        }

        print("Contacts (\(contacts.count) total)")
        print(String(repeating: "-", count: 50))

        for contact in contacts.prefix(limit) {
            let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
            let org = contact.organizationName.isEmpty ? "" : " - \(contact.organizationName)"
            print("  \(name)\(org)")
        }
    } catch {
        print("Error listing contacts: \(error.localizedDescription)")
    }
}

func printUsage() {
    print("""
    mac-contacts - Query macOS Contacts

    USAGE:
        mac-contacts [COMMAND] [OPTIONS]

    COMMANDS:
        list            List contacts (default)
        search <name>   Search contacts by name

    OPTIONS:
        --limit N       Limit results (default: 20)
        --json          Output as JSON
        --help          Show this help

    EXAMPLES:
        mac-contacts                 # List contacts
        mac-contacts search John     # Search for John
    """)
}

@main
struct ContactsCLI {
    static func main() async {
        let args = Array(CommandLine.arguments.dropFirst())

        if args.contains("--help") || args.contains("-h") {
            printUsage()
            return
        }

        let granted = await requestAccess()
        guard granted else {
            fputs("Error: Contacts access denied.\n", stderr)
            fputs("Grant access in: System Settings > Privacy & Security > Contacts\n", stderr)
            exit(1)
        }

        let command = args.first { !$0.hasPrefix("-") } ?? "list"

        switch command {
        case "list":
            listRecentContacts()
        case "search":
            if let idx = args.firstIndex(of: "search"), idx + 1 < args.count {
                let query = args[idx + 1]
                searchContacts(query: query)
            } else {
                print("Usage: mac-contacts search <name>")
            }
        default:
            listRecentContacts()
        }
    }
}
