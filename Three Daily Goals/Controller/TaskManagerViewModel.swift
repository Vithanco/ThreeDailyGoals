//
//  ContentViewModel.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 29/12/2023.
//

import Foundation
import SwiftData
import SwiftUI
import os
import CoreData

fileprivate let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier!,
    category: String(describing: TaskManagerViewModel.self)
)

@Observable
class ListViewModel {
    var section: TaskSection
    var list: [TaskItem]
    
    init(section: TaskSection, list: [TaskItem]) {
        self.section = section
        self.list = list
    }
}

extension TaskItemState {
    var section: TaskSection {
        switch self {
            case .open : return secOpen
            case .closed: return secClosed
            case .dead: return secGraveyard
            case .priority: return secToday
            case .pendingResponse: return secPending
        }
    }
}

@Observable
final class TaskManagerViewModel {
    
    var timer : ReviewTimer = ReviewTimer()
    let modelContext: Storage
    private(set) var items = [TaskItem]()
    var isTesting = false
    
    var preferences: CloudPreferences
    
    var accentColor: Color {
        return preferences.accentColor
    }
    
    func select(which: TaskItemState, item: TaskItem?) {
        withAnimation {
            whichList = which
            selectedItem = item
        }
    }
    
    ///used in Content view of NavigationSplitView
    var whichList = TaskItemState.open
    
    /// used in Detail View of NavigationSplitView
    var selectedItem: TaskItem? = nil
    
    var showItem: Bool
    var canUndo = false
    var canRedo = false
    
    var showReviewDialog: Bool = false
    var showSettingsDialog: Bool = false
    var showMissingReviewAlert : Bool = false
    
    
    var lists : [TaskItemState: [TaskItem]] = [:]
    
    // for export
    var showFileName: Bool = false
    var fileUrl: String =  "(invalid)"
    
    init(modelContext: Storage, preferences: CloudPreferences, isTesting : Bool = false) {
        self.modelContext = modelContext
        self.preferences = preferences
        self.isTesting = isTesting
        self.showItem = false
        for c in TaskItemState.allCases {
            lists[c] = []
        }
        fetchData()
        NotificationCenter.default.addObserver(forName: NSPersistentCloudKitContainer.eventChangedNotification, object: nil, queue: OperationQueue.main){(notification) in
            if let userInfo = notification.userInfo {
                logger.debug("\(userInfo.debugDescription)")
                if let event = userInfo["event"] as? NSPersistentCloudKitContainer.Event {
                    if event.type == .import && event.endDate != nil && event.succeeded {
                        logger.debug("update my list of Tasks")
                        self.fetchData()
                    }
                }
            }
        }
        setupReviewNotification()
    }
    
    func addSamples() -> Self {
        let lastWeek1 = TaskItem(title: "3 days ago", changedDate: getDate(daysPrior: 3))
        let lastWeek2 = TaskItem(title: "5 days ago", changedDate: getDate(daysPrior: 5))
        let lastMonth1 = TaskItem(title: "11 days ago", changedDate: getDate(daysPrior: 11))
        let lastMonth2 = TaskItem(title: "22 days ago", changedDate: getDate(daysPrior: 22))
        let older1 = TaskItem(title: "31 days ago", changedDate: getDate(daysPrior: 31))
        let older2 = TaskItem(title: "101 days ago", changedDate: getDate(daysPrior: 101))
        move(task: lastWeek1, to: .priority)
        modelContext.insert(lastWeek1)
        modelContext.insert(lastWeek2)
        modelContext.insert(lastMonth1)
        modelContext.insert(lastMonth2)
        modelContext.insert(older1)
        modelContext.insert(older2)
        
        try? modelContext.save()
        fetchData()
        return self
    }
    
//    func clear() {
//        try? modelContext.delete(model: TaskItem.self)
//        try? modelContext.save()
//        fetchData()
//    }
//    
    func fetchData() {
        do {
            let descriptor = FetchDescriptor<TaskItem>(sortBy: [SortDescriptor(\.changed, order: .forward)])
            items = try modelContext.fetch(descriptor)
            logger.info("fetched \(self.items.count) tasks from central store")
            for t in lists.keys {
                lists[t]?.removeAll(keepingCapacity: true)
            }
            for item in items {
                lists[item.state]?.append(item)
            }
            for t in lists.keys {
                lists[t]?.sort()
            }
            updateUndoRedoStatus()
            
            setupReviewNotification()
        } catch {
            print("Fetch failed")
        }
    }
   
    @discardableResult func quickAddItem(title: String = emptyTaskTitle, details: String = emptyTaskDetails, changedDate: Date = Date.now, state: TaskItemState = .open) -> TaskItem {
        let newItem = TaskItem(title: title, details: details, changedDate: changedDate, state: state)
        modelContext.insert(newItem)
        items.append(newItem)
        self.lists[.open]?.append(newItem)
        modelContext.processPendingChanges()
        return newItem
    }
    
    @discardableResult func addItem(title: String  = emptyTaskTitle, details: String = emptyTaskDetails, changedDate: Date = Date.now, state: TaskItemState = .open) -> TaskItem {
        let newItem = quickAddItem(title: title, details: details, changedDate: changedDate, state: state)
#if os(macOS)
        select(which: .open, item: newItem)
#endif
#if os(iOS)
        selectedItem = newItem
        showItem = true
#endif
        updateUndoRedoStatus()
        return newItem
    }
    
    func undo() {
        withAnimation {
            modelContext.processPendingChanges()
            modelContext.undo()
            modelContext.processPendingChanges()
            fetchData()
        }
    }
    
    func redo() {
        withAnimation {
            modelContext.processPendingChanges()
            modelContext.redo()
            modelContext.processPendingChanges()
            fetchData()
        }
    }
    
    func updateUndoRedoStatus() {
        modelContext.processPendingChanges()
        modelContext.processPendingChanges()
        canUndo =  modelContext.canUndo
        canRedo =  modelContext.canRedo
    }
    
    func findTask(withID: String) -> TaskItem? {
        let result = items.first(where: {$0.id == withID})
        logger.debug("found Task '\(result != nil)' for ID: \(withID)")
        return result
    }
    
    func touch(task: TaskItem) {
        task.touch()
        updateUndoRedoStatus()
    }
    
    func delete(task: TaskItem) {
        withAnimation {
            modelContext.beginUndoGrouping()
            modelContext.delete(task)
            lists[task.state]?.removeObject(task)
            if let index = items.firstIndex(of: task) {
                items.remove(at: index)
            }
            for c in task.comments ?? [] {
                modelContext.delete(c)
            }
            modelContext.endUndoGrouping()
            updateUndoRedoStatus()
        }
    }
    
    
    ///updating priorities to key value store, so that we show them in the Widget
    fileprivate func updatePriorities() {
        if let prioTasks = lists[.priority] {
            let prios = prioTasks.count
            for i in 0..<prios {
                preferences.setPriority(nr: i+1, value: prioTasks[i].title)
            }
            if prios < 5 {
                for i in prios...4 {
                    preferences.setPriority(nr: i+1, value: "")
                }
            }
        }
    }
    
    func move(task: TaskItem, to: TaskItemState) {
        if task.state == to {
            return // nothing to be done
        }
        let moveFromPriority = task.state == .priority
        lists[task.state]?.removeObject(task)
        switch to {
            case .open:
                task.reOpenTask()
            case .closed:
                task.closeTask()
            case .dead:
                task.graveyard()
            case .priority:
                task.makePriority()
            case .pendingResponse:
                task.pending()
        }
        lists[to]?.append(task)
        lists[to]?.sort()
        
        // Did it touch priorities (in or out)? If so, update priorities
        if to == .priority || moveFromPriority {
            updatePriorities()
        }
        updateUndoRedoStatus()
    }
    
    var nextRegularReviewTime: Date {
        var result = self.preferences.reviewTime
        if Calendar.current.isDate(preferences.lastReview, inSameDayAs: result) {
            // review happened today, let's do it tomorrow
            result = addADay(result)
        } else { // today's review missing
            if result < Date.now {
                //regular time passed by, now just do it in 30 secs
                return Date.now.addingTimeInterval(Seconds.thirtySeconds)
            }
        }
        return result
    }
    
    func setupReviewNotification(when: Date? = nil){
        scheduleSystemPushNotification(timing: preferences.reviewTimeComponents, model: self)
        if showReviewDialog {
            return
        }
        if isTesting {
            return
        }
        let time = when ?? nextRegularReviewTime

        showReviewDialog = false
        timer.setTimer(forWhen: time ){
            if self.showReviewDialog {
                return
            }
            self.reviewNow()
            self.setupReviewNotification()
        }
    }
    func resetAccentColor(){
        preferences.resetAccentColor()
    }
    
    
    /// updating  streak if that is meaningful
    fileprivate func updateStreak() {
        if Calendar.current.isDate(preferences.lastReview, inSameDayAs: Date.now) {
            //nothing to do, we already got today's credit
            return
        }
        
        if preferences.lastReview.addingTimeInterval(Seconds.thirtySixHours) > Date.now {
            preferences.daysOfReview = preferences.daysOfReview + 1
        } else {
            // reset the streak to 0
            preferences.daysOfReview = 0
        }
    }
    
    func endReview(){
        showReviewDialog = false
        
        updateStreak()
        
        // setting last review date
        preferences.lastReview = Date.now
    }
    
    @discardableResult func killOldTasks(expireAfter: Int? = nil) -> Int{
        var result = 0
        let expiryDays = expireAfter ?? preferences.expiryAfter
        let expireData = getDate(daysPrior: expiryDays)
        result += killOldTasks(expiryDate: expireData, whichList: .open)
        result += killOldTasks(expiryDate: expireData, whichList: .priority)
        result += killOldTasks(expiryDate: expireData, whichList: .pendingResponse)
        logger.info("killed \(result) tasks")
        return result
    }
    
    func killOldTasks(expiryDate: Date, whichList: TaskItemState) -> Int {
        let theList = list(which: whichList)
        var result = 0
        for task in theList {
            if task.changed < expiryDate {
                move(task: task, to: .dead)
                result += 1
            }
        }
        return result
    }
    
    func reviewNow(){
        logger.info("start review \(Date.now)")
        showReviewDialog = true
    }
}

extension TaskManagerViewModel {
    func list(which: TaskItemState) -> [TaskItem] {
        guard let result = lists[which] else {
            logger.fault("couldn't retrieve list \(which) from lists")
            return []
        }
        return result
    }
    
    var currentList: [TaskItem] {
        return list(which: whichList)
    }
}

//
//extension TaskManagerViewModel {
//    internal var undoManager: UndoManager? {
//        return modelContext.undoManager
//    }
//}

extension TaskManagerViewModel {
    
    // for testing purposes
    var hasUndoManager: Bool {
        return modelContext.undoManager != nil
    }
    
    func beginUndoGrouping() {
        modelContext.beginUndoGrouping()
        updateUndoRedoStatus()
    }
    
    func endUndoGrouping() {
        modelContext.endUndoGrouping()
        updateUndoRedoStatus()
    }
}


func dummyViewModel() -> TaskManagerViewModel {
    return TaskManagerViewModel(modelContext: TestStorage(), preferences: dummyPreferences(), isTesting: true)
}

