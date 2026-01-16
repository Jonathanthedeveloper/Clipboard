//
//  ContentView.swift
//  Clipboard
//
//  Created by Jonathan Amobi on 15/01/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject var manager = ClipboardManager()
    @State private var searchText = ""
    @State private var revealedItemId: UUID? = nil
    @State private var selectedIndex: Int = 0
    
    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return manager.items
        }
        return manager.items.filter { item in
            if case .text = item.kind, let text = item.text {
                return text.localizedCaseInsensitiveContains(searchText)
            }
            return false
        }
    }
    
    var pinnedItems: [ClipboardItem] {
        filteredItems.filter { $0.pinned }
    }
    
    var recentItems: [ClipboardItem] {
        filteredItems.filter { !$0.pinned }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Clipboard")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
                if !manager.items.isEmpty {
                    Button(action: { 
                        withAnimation(.easeOut(duration: 0.25)) {
                            manager.clear()
                        }
                    }) {
                        Text("Clear All")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 12))
                TextField("Type to search...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            
            Divider()
                .opacity(0.5)
            
            if manager.items.isEmpty {
                EmptyStateView()
            } else if filteredItems.isEmpty {
                NoResultsView(searchText: searchText)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 6) {
                            ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                                ClipboardCard(
                                    item: item,
                                    isRevealed: revealedItemId == item.id,
                                    isSelected: selectedIndex == index,
                                    onRevealToggle: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            if revealedItemId == item.id {
                                                revealedItemId = nil
                                            } else {
                                                revealedItemId = item.id
                                            }
                                        }
                                    },
                                    onMainClick: {
                                        manager.copyToClipboard(item)
                                        selectedIndex = index // Keep selection on this item
                                    },
                                    onPasteAsText: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            revealedItemId = nil
                                        }
                                        manager.copyToClipboard(item) 
                                        manager.pasteIntoFrontmostApp()
                                        selectedIndex = index // Keep selection on this item
                                    },
                                    onPin: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            if item.pinned { manager.unpin(item) } else { manager.pin(item) }
                                        }
                                    },
                                    onDelete: {
                                        withAnimation(.easeOut(duration: 0.25)) {
                                            revealedItemId = nil
                                            manager.remove(item)
                                        }
                                    }
                                )
                                .id(item.id)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                                    removal: .scale(scale: 0.9).combined(with: .opacity).combined(with: .move(edge: .trailing))
                                ))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    }
                    .scrollContentBackground(.hidden)
                    .onChange(of: selectedIndex) { _, newIndex in
                        if newIndex >= 0 && newIndex < filteredItems.count {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                proxy.scrollTo(filteredItems[newIndex].id, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
        .frame(width: 340, height: 480)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(.escape) {
            if revealedItemId != nil {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    revealedItemId = nil
                }
            } else {
                NSApplication.shared.hide(nil)
            }
            return .handled
        }
        .onKeyPress(.downArrow) {
            if selectedIndex < filteredItems.count - 1 {
                selectedIndex += 1
            }
            return .handled
        }
        .onKeyPress(.upArrow) {
            if selectedIndex > 0 {
                selectedIndex -= 1
            }
            return .handled
        }
        .onKeyPress(.return) {
            if selectedIndex >= 0 && selectedIndex < filteredItems.count {
                manager.copyToClipboard(filteredItems[selectedIndex])
            }
            return .handled
        }
        .onChange(of: filteredItems.count) { _, newCount in
            if selectedIndex >= newCount {
                selectedIndex = max(0, newCount - 1)
            }
        }
    }
}

struct ClipboardCard: View {
    let item: ClipboardItem
    let isRevealed: Bool
    let isSelected: Bool
    let onRevealToggle: () -> Void
    let onMainClick: () -> Void
    let onPasteAsText: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovered = false
    @Environment(\.colorScheme) var colorScheme
    
    private var isHighlighted: Bool {
        isHovered || isSelected
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            actionsLayer
            mainContentLayer
        }
        .id(item.id)
    }
    
    private var actionsLayer: some View {
        HStack(spacing: 2) {
            Spacer()
            
            Button(action: onPasteAsText) {
                ZStack {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .frame(width: 72, height: 72)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .glassEffect(in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .help("Paste")
            
            Button(action: onDelete) {
                ZStack {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.red)
                }
                .frame(width: 72, height: 72)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .glassEffect(in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .help("Delete")
        }
        .frame(height: 72)
        .padding(.trailing, 0)
        .opacity(isRevealed ? 1 : 0)
    }
    
    private var mainContentLayer: some View {
        HStack(spacing: 12) {
            contentPreview
            Spacer(minLength: 0)
            sideActionButtons
        }
        .padding(.leading, 12)
        .padding(.trailing, 6)
        .padding(.vertical, 8)
        .frame(height: 72)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    colorScheme == .light 
                    ? AnyShapeStyle(Color.black.opacity(0.04))
                    : AnyShapeStyle(.thickMaterial)
                )
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(
                    isHighlighted ? Color.accentColor.opacity(0.5) : Color.white.opacity(0.2),
                    lineWidth: isSelected ? 1.5 : 0.5
                )
        )
        .offset(x: isRevealed ? -148 : 0)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isRevealed)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            if isRevealed {
                onRevealToggle()
            } else {
                onMainClick()
            }
        }
    }

    private var contentPreview: some View {
        HStack(alignment: .center, spacing: 12) {
            if item.kind == .text {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.text ?? "")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(relativeTime)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if item.kind == .image, let img = item.thumbnail() {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.1), lineWidth: 1))
                
                VStack(alignment: .leading) {
                    Text("Image")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                    Text(relativeTime)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            }
        }
    }
    
    private var relativeTime: String {
        let interval = Date().timeIntervalSince(item.dateAdded)
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let mins = Int(interval / 60)
            return "\(mins)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
    
    private var sideActionButtons: some View {
        VStack(spacing: 0) {
            IconButton(icon: "ellipsis", help: "More Actions", action: onRevealToggle)
            
            Spacer()
            
            IconButton(
                icon: item.pinned ? "pin.fill" : "pin",
                help: item.pinned ? "Unpin" : "Pin",
                isActive: item.pinned,
                action: onPin
            )
        }
        .padding(.vertical, 12)
        .padding(.trailing, 4)
    }
}

struct IconButton: View {
    let icon: String
    var help: String? = nil
    var isActive: Bool = false
    var activeColor: Color = .accentColor
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isActive ? activeColor : .secondary)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
                .background(
                    Group {
                        if isHovered {
                            Color.clear
                                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                        } else {
                            Color.clear
                        }
                    }
                )
        }
        .buttonStyle(.plain)
        .help(help ?? "")
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.tertiary)
            Text("No clipboard history")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Text("Copy something to get started")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct NoResultsView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.tertiary)
            Text("No results for \"\(searchText)\"")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

