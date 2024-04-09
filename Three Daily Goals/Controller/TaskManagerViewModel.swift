//
//  ContentViewModel.swift
//  Three Daily Goals
//
//  Created by Klaus Kneupner on 29/12/2023.
//

import Foundation
import SwiftData
import SwiftUI
import CoreData
import os
import CloudKit

nonisolated(unsafe) private let logger = Logger(
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

struct Choice {
    let existing: TaskItem
    let new: TaskItem
}

@Observable
final class TaskManagerViewModel{
    
    let timer : ReviewTimer = ReviewTimer()
    let modelContext: Storage
    private(set) var items = [TaskItem]()
    var isTesting : Bool = false
    
    //Import/Export
    public var showImportDialog : Bool = false
    public var showExportDialog : Bool = false
    var jsonExportDoc: JSONWriteOnlyDoc? = nil
    
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
    var showSelectDuringImportDialog: Bool = false
    var selectDuringImport: [Choice] = []
    
    var streakText: String = ""
    
    var lists : [TaskItemState: [TaskItem]] = [:]
    
    // for user messages
    var showInfoMessage: Bool = false
    var infoMessage: String =  "(invalid)"
    func finishDialog() {
        showInfoMessage = false
    }
    
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
    fileprivate func sortList(_ t: TaskItemState) {
        lists[t]?.sort(by: t.sorter)
    }
    
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
                sortList(t)
            }
            updateUndoRedoStatus()
            
            setupReviewNotification()
        } catch {
            print("Fetch failed")
        }
    }
   
    @discardableResult func addItem(title: String = emptyTaskTitle, details: String = emptyTaskDetails, changedDate: Date = Date.now, state: TaskItemState = .open) -> TaskItem {
        let newItem = TaskItem(title: title, details: details, changedDate: changedDate, state: state)
        addItem(item: newItem)
        return newItem
    }
    
    public var isProductionEnvironment: Bool {
        return CKContainer.isProductionEnvironment
    }
    
    func addItem(item: TaskItem) {
        modelContext.insert(item)
        if let comments = item.comments {
            for c in comments {
                modelContext.insert(c)
            }
        }
        items.append(item)
        self.lists[item.state]?.append(item)
        sortList(item.state)
        modelContext.processPendingChanges()
        updateUndoRedoStatus()
    }
    
    fileprivate func select(_ newItem: TaskItem) {
#if os(macOS)
        select(which: newItem.state, item: newItem)
#endif
#if os(iOS)
        selectedItem = newItem
        showItem = true
#endif
    }
    
     func addNewItem() {
         addAndSelect()
    }
    
    @discardableResult func addAndSelect(title: String  = emptyTaskTitle, details: String = emptyTaskDetails, changedDate: Date = Date.now, state: TaskItemState = .open) -> TaskItem {
        let newItem = addItem(title: title, details: details, changedDate: changedDate, state: state)
        select(newItem)
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
        
        let next = self.nextRegularReviewTime
        let today = preferences.lastReview.isToday ? "Done" : stdOnlyTimeFormat.format(next)
        streakText = "Streak: \(self.preferences.daysOfReview), today: \(today)"  //- Time:
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
            lists[task.state]?.removeObject(task)
            if let index = items.firstIndex(of: task) {
                items.remove(at: index)
            }
            for c in task.comments ?? [] {
                modelContext.delete(c)
            }
            modelContext.delete(task)
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
        sortList(to)
        
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
        updateUndoRedoStatus()
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
    
    func remove(item: TaskItem) {
        items.removeObject(item)
        lists[item.state]?.removeObject(item)
        self.modelContext.delete(item)
    }
    
    func showPreferences() {
        showSettingsDialog = true
    }
    
    func removeItem(withID: String) {
        if let item = items.first(where: {$0.id == withID}) {
            remove(item: item)
        }
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



func dummyViewModel(loader: TestStorage.Loader? = nil) -> TaskManagerViewModel {
    let loader = loader ?? loadStdItems
    return TaskManagerViewModel(modelContext: TestStorage(loader: loader), preferences: dummyPreferences(), isTesting: true)
}

func loadStdItems() -> [TaskItem] {
    var result : [TaskItem] = []
    let theGoal = result.add(title: "Read 'The Goal' by Goldratt", changedDate: Date.now.addingTimeInterval(-1 * Seconds.fiveMin))
    theGoal.details = "It is the book that introduced the fundamentals for 'Theory of Constraints'"
    theGoal.url = "https://www.goodreads.com/book/show/113934.The_Goal"
    result.add(title: "Try out Concept Maps", changedDate: getDate(daysPrior: 3), state: .priority)
    result.add(title: "Read about Systems Thinking", changedDate: getDate(daysPrior: 5))
    result.add(title: "Transfer tasks from old task manager into this one", changedDate: getDate(daysPrior: 11), state: .open)
    let lastMonth2 = result.add(title: "Read about Structured Visual Thinking", changedDate: getDate(daysPrior: 22),state: .pendingResponse)
    lastMonth2.url = "https://vithanco.com"
    result.add(title: "Contact Vithanco Author regarding new map style", changedDate: getDate(daysPrior: 3),state: .pendingResponse)
    result.add(title: "Read this", changedDate: getDate(daysPrior: 31), state: .dead)
    result.add(title: "Read this about Agile vs Waterfall", changedDate: getDate(daysPrior: 101), state: .dead)
    return result
}
