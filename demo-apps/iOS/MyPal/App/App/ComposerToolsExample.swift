//
//  ComposerToolsExample.swift
//  Simple
//
//  Example showing how to register and use composer tools with logos
//  Tools represent external services that can be invoked to fulfill user requests
//

import UIKit
import ConvoUI

/// Example: Register tools/services with logos in the composer
/// Tools are external services (APIs, platforms) that the LLM can use to answer user queries
class ComposerToolsExample {
    
    /// Create example composer tools with logos
    /// These represent real services that can be called to fulfill user requests
    static func createExampleTools() -> [FinConvoComposerTool] {
        var tools: [FinConvoComposerTool] = []
        
        // Example 1: Expedia - Travel Booking Service
        let expediaLogo = UIImage(named: "tool_expedia") ?? UIImage(systemName: "airplane")?.withTintColor(.systemOrange, renderingMode: .alwaysOriginal)
        let expediaTool = FinConvoComposerTool(
            itemId: "expedia",
            displayName: "Expedia",
            logoImage: expediaLogo
        )
        expediaTool.badgeColor = .systemOrange
        expediaTool.metadata = [
            "endpoint": "https://api.expedia.com/v1",
            "service": "travel",
            "description": "Search and book flights, hotels, and vacation packages",
            "capabilities": ["flights", "hotels", "car-rentals", "vacation-packages"]
        ]
        tools.append(expediaTool)
        
        // Example 2: Booking.com - Accommodation Service
        let bookingLogo = UIImage(named: "tool_booking") ?? UIImage(systemName: "building.2")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
        let bookingTool = FinConvoComposerTool(
            itemId: "booking",
            displayName: "Booking.com",
            logoImage: bookingLogo
        )
        bookingTool.badgeColor = .systemBlue
        bookingTool.metadata = [
            "endpoint": "https://api.booking.com/v2",
            "service": "accommodation",
            "description": "Find and book hotels, apartments, and accommodations worldwide",
            "capabilities": ["hotels", "apartments", "hostels", "resorts"]
        ]
        tools.append(bookingTool)
        
        // Example 3: Coursera - Online Learning Service
        let courseraLogo = UIImage(named: "tool_coursera") ?? UIImage(systemName: "book.fill")?.withTintColor(.systemIndigo, renderingMode: .alwaysOriginal)
        let courseraTool = FinConvoComposerTool(
            itemId: "coursera",
            displayName: "Coursera",
            logoImage: courseraLogo
        )
        courseraTool.badgeColor = .systemIndigo
        courseraTool.metadata = [
            "endpoint": "https://api.coursera.org/v1",
            "service": "education",
            "description": "Search and enroll in online courses from top universities and companies",
            "capabilities": ["courses", "specializations", "degrees", "certificates"]
        ]
        tools.append(courseraTool)
        
        return tools
    }
    
    
    /// Example: Handle composer tool selection
    /// When a user selects a tool, it will be included with their message
    static func handleComposerToolSelected(_ tool: FinConvoComposerTool) {
        print("✅ Tool selected for this message: \(tool.displayName) (ID: \(tool.itemId))")
        
        if let metadata = tool.metadata as? [String: Any] {
            print("   Service: \(metadata["service"] ?? "N/A")")
            print("   Endpoint: \(metadata["endpoint"] ?? "N/A")")
            print("   Description: \(metadata["description"] ?? "N/A")")
            if let capabilities = metadata["capabilities"] as? [String] {
                print("   Capabilities: \(capabilities.joined(separator: ", "))")
            }
        }
        
        // The selected tool will be sent with the user's message to the backend
        // The LLM can then use this tool to fulfill the user's request
        // Example: User says "Find me a hotel" + selects Booking.com
        //          → Backend/LLM uses Booking.com API to search for hotels
    }
    
    /// Example: Update a composer tool dynamically
    static func updateComposerTool(_ chatView: FinConvoChatView, itemId: String, newDisplayName: String) {
        let updatedTool = FinConvoComposerTool(
            itemId: itemId,
            displayName: newDisplayName,
            logoImage: UIImage(systemName: "star.fill")?.withTintColor(.systemYellow, renderingMode: .alwaysOriginal)
        )
        updatedTool.badgeColor = .systemYellow
        
        chatView.update(updatedTool)
        print("✅ Updated composer tool: \(itemId) → \(newDisplayName)")
    }
    
    /// Example: Remove a composer tool
    static func removeComposerTool(_ chatView: FinConvoChatView, itemId: String) {
        chatView.removeComposerTool(withId: itemId)
        print("✅ Removed composer tool: \(itemId)")
    }
    
    /// Example: Get all registered tools
    static func listComposerTools(_ chatView: FinConvoChatView) {
        let tools = chatView.registeredComposerTools()
        print("📋 Registered composer tools (\(tools.count)):")
        for tool in tools {
            print("   - \(tool.displayName) (ID: \(tool.itemId))")
        }
    }
}
