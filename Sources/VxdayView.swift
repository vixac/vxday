//
//  VxdayView.swift
//  vxday
//
//  Created by vic on 26/07/2017.
//  Copyright © 2017 vixac. All rights reserved.
//

import Foundation


struct VxColor {
    let ansi: ANSIColor

    init(_ ansi: ANSIColor) {
        self.ansi = ansi
    }
    static func danger() -> VxColor {
        return VxColor(.red)
    }
    static func warning() -> VxColor {
        return VxColor(.yellow)
    }
    static func base() -> VxColor {
        return VxColor(.reset)
    }
    static func happy() -> VxColor {
        return VxColor(.green)
    }
    static func title() -> VxColor {
        return VxColor(.white)
    }
    static func neutral() -> VxColor {
        return VxColor(.reset)
    }
    static func info2() -> VxColor {
        return VxColor(.test)
    }
    static func info() -> VxColor {
        return VxColor(.cyan)
    }
    static func white() -> VxColor {
        return VxColor(.white)
    }
    static func boldInfo() -> VxColor {
        return VxColor(.white)
    }
    static func bright() -> VxColor {
        return VxColor(.magenta)
    }
    static func black() -> VxColor {
        return VxColor(.black)
    }
    func colorThis(_ string: String) -> String {
        return ansi.rawValue + string + ANSIColor.reset.rawValue
    }
    
    
    static func putBack() {
        print(ANSIColor.reset.rawValue)
    }
}


//TODO RM
class VxdayColor {
    static let dangerColor : ANSIColor = ANSIColor.red
    static let warningColor : ANSIColor = ANSIColor.yellow
    static let baseColor : ANSIColor = ANSIColor.reset
    static let happyColor: ANSIColor = ANSIColor.green
    static let titleColor :ANSIColor = ANSIColor.white
    static let info2Color: ANSIColor = ANSIColor.test
    static let infoColor: ANSIColor = ANSIColor.cyan
    static let whiteColor : ANSIColor = ANSIColor.white
    
    static func danger(_ string: String) -> String {
        return dangerColor.rawValue + string + baseColor.rawValue
    }
    static func warning(_ string: String) -> String {
        return warningColor.rawValue + string + baseColor.rawValue
    }
    static func title(_ string: String) -> String {
        return titleColor.rawValue + string + baseColor.rawValue
    }
    static func happy(_ string: String) -> String {
        return happyColor.rawValue + string + baseColor.rawValue
    }
    static func info(_ string: String) -> String {
        return infoColor.rawValue + string + baseColor.rawValue
    }
    static func info2(_ string: String) -> String {
        return info2Color.rawValue + string + baseColor.rawValue
    }
    static func boldInfo(_ string: String) -> String {
        return whiteColor.rawValue + string + baseColor.rawValue
    }
    
    
    static func putBack() {
        print(ANSIColor.reset.rawValue)
    }
}

enum ANSIColor: String {
    case black = "\u{001B}[0;30m"
    case red = "\u{001B}[0;31m"
    case green = "\u{001B}[0;32m"
    case yellow = "\u{001B}[0;33m"
    case blue = "\u{001B}[0;34m"
    case magenta = "\u{001B}[0;35m"
    case cyan = "\u{001B}[0;36m"
    case white = "\u{001B}[1;37m"
    case test = "\u{001B}[1;34m"
    case reset = "\u{001B}[0;0m"
}





class ListSummary {
    let list: ListName
    var past: [VxJob] = []
    var present: [VxJob] = []
    var future: [VxJob] = []
    var taskCount: Int = 0
    var nowCount: Int = 0
    var timeWorked: Int = 0
    init(_ list: ListName) {
        self.list = list
    }
    func addJob(_ job: VxJob) {
        let bucket = job.deadline.date.bucket()
        switch bucket {
        case .past:
            past.append(job)
        case .present:
            present.append(job)
        case .future:
            future.append(job)
        }
    }
     func addTask(_ task: VxTask) {
        taskCount += 1
    }
    func addNow(_ now: VxNow) {
        nowCount += 1
    }
    func addToken(_ token: VxToken) {
        let breakdown = token.timeBreakdown()
        timeWorked += breakdown.totalSeconds
    }
    func total() -> Int {
        return past.count + present.count + future.count + taskCount + nowCount
    }
}



class HashSummary {
    var hash: Hash
    var description: Description?
    var tokens: [VxToken] = []
    var totalSeconds: Int = 0
    
    init(_ hash: Hash, description : Description?) {
        self.hash = hash
        self.description = description
    }
    func addToken(_ token: VxToken) {
        tokens.append(token)
        totalSeconds += token.breakdown.totalSeconds
    }
}

class ListTokensSummary {
    var list: ListName
    var hashes: [Hash: HashSummary] = [:]
    var totalSeconds : Int = 0
    init(_ list: ListName) {
        self.list = list
    }
    func addToken(_ token: VxToken) {
        if list != token.list {
            print("Dev error, adding list: \(token.list) to listTokenSummary for list: \(list)")
            return
        }
        totalSeconds += token.breakdown.totalSeconds
        if let summary = hashes[token.hash] {
            summary.addToken(token)
        }
        else {
            
            let hashSummary = HashSummary(token.hash, description: token.description )
            hashSummary.addToken(token)
            hashes[token.hash] = hashSummary
        }
    }
}

class DaySummary {
    let date: CreationDate
    var listSummaries: [ListName: ListTokensSummary] = [:]
    var totalSeconds: Int = 0
    
    init(_ date: CreationDate ) {
        self.date = date
    }

    func addToken(_ token: VxToken) {
        totalSeconds += TimeBreakdown(start: token.creation.date, end: token.completion.date).totalSeconds
        if let current = listSummaries[token.list] {
            current.addToken(token)
        }
        else {
            let listTokenSummary = ListTokensSummary(token.list)
            listTokenSummary.addToken(token)
            listSummaries[token.list] = listTokenSummary
        }
    }
    
    func getSorted() -> [(list: ListName, duration: IntOffset)] {
        var tuples: [(list: ListName, duration: IntOffset)] = []
        for (list, hashSummary) in listSummaries {
            tuples.append((list: list, duration:IntOffset(hashSummary.totalSeconds)))
        }
        return tuples.sorted(by: {$0.duration.offset < $1.duration.offset})
    }
    
}


class TokenDayView {
    
    //TODO make CreationDate hashable
    var days: [Date : DaySummary] = [:]
    func addToken(_ token: VxToken) {
        let day = token.creation.date.startOfDay()
        if let _ = days[day] {
            days[day]?.addToken(token)
        }
        else {
            let summary = DaySummary(CreationDate(day))
            summary.addToken(token)
            days[day] = summary
        }
    }
    
    
    static func dateOfStart(daysAgo: IntOffset) -> Date {
        return  VxdayUtil.now().startOfDay().incrementByDays(abs(daysAgo.offset) * -1)
    }
    
    
    func createSummaries(numDays: IntOffset) -> [Date: DaySummary] {
        let todayStart = VxdayUtil.now().startOfDay()
        let absDays = abs(numDays.offset)
        var result: [Date: DaySummary] = [:]
        for i in 0...absDays {
            let date = todayStart.addingTimeInterval(TimeInterval(i * Date.SECONDS_IN_A_DAY * -1))
            if let summary = days[date] {
                result[date] = summary
            }
            else {
                result[date] = DaySummary(CreationDate(date))
            }
        }
        return result
    }

    func toTable(_ days: IntOffset, width: Int) -> VxdayTable {
        let table = VxdayTable( "Token summary", width: width)
        let daySummaries = self.createSummaries(numDays: days)
        let sortedDayKeys = daySummaries.keys.sorted()

        
        var grandTotalSeconds : Int = 0
        sortedDayKeys.forEach { date in
            let summary = daySummaries[date]!
            grandTotalSeconds += summary.totalSeconds

            table.addHeading("  \(date.daysAgo()) \(VxdayUtil.dateFormatter.string(from: date))  ", char: "-", color: VxColor.base())
            
            var listTotalSeconds: Int = 0
            
            let listSummaries = summary.listSummaries
            for(list, listSummary) in listSummaries {
                let duration = listSummary.totalSeconds
                listTotalSeconds += duration
                let listCell = Cell.list(list)
                let breakdown = Cell.text(TimeBreakdown(IntOffset(duration)).toString(), VxColor.info())
                table.addRow([listCell, breakdown])
                let hashSummaries = listSummary.hashes
                for (hash, hashSummary) in hashSummaries {
                    let total = hashSummary.totalSeconds
                    let emptyCell = Cell.hash(nil)
                    let hashCell = Cell.hash(hash)
                    let timeCell = Cell.timeliness(TimeBreakdown(IntOffset(total)))
                    let descriptionCell = Cell.text(hashSummary.description?.text, VxColor.base())
                    table.addRow([emptyCell, emptyCell, hashCell, timeCell, descriptionCell])
                }
            }
            
            //table.addHeading("", char: "-", color: VxColor.black())
            
          //  if listSummaries.count > 1 {
                let listBreakdown = TimeBreakdown(IntOffset(listTotalSeconds))
                table.addRow([Cell.text("Total: ", VxColor.happy()), Cell.text(listBreakdown.toString(), VxColor.happy())])
//            }
            
            table.addHeading("", char: " ", color: VxColor.black())
            
        }
        table.addHeading("", char: "=", color: VxColor.base())
        
        table.addRow([Cell.text("Total: ", VxColor.happy()), Cell.text(TimeBreakdown(IntOffset(grandTotalSeconds)).toString(), VxColor.happy())])
        return table
    }
}


class CompleteTableView {
    let items: [Item]
    init(_ items : [Item]) {
        self.items = items 
    }
    
    func toTable(_ width: Int) -> VxdayTable {
        
        let table = VxdayTable( "", width: width)

        var rows: [TimeInterval : [Cell]] = [:]
        items.filter { $0.getJob() != nil || $0.getTask() != nil || $0.getNow() != nil  }.forEach { item in
            var offsetFromDeadline: Int? = nil
            if let j = item.getJob() {
                guard let completion = j.completion else {
                    print("Error missing completion for job: \(j)")
                    return
                }
                offsetFromDeadline = VxdayUtil.timeliness(deadline: j.deadline, completion: completion)
                let completedCell = Cell.text(j.completion!.date.daysAgo(), VxColor.base())
                let dateCell = Cell.text(VxdayUtil.dateFormatter.string(from: completion.date), VxColor.base())
                let timelinessStr = VxdayUtil.timelinessToString(VxdayUtil.timeliness(deadline: j.deadline, completion: completion))
                var color: VxColor = VxColor.base()
                if let o = offsetFromDeadline {
                    if o < 0 {
                        color = VxColor.danger()
                    }
                    else if o == 0 {
                        color = VxColor.warning()
                    }
                    else {
                        color = VxColor.happy()
                    }
                }
                let listCell = Cell.list(j.list)
                let timelinessCell = Cell.text(timelinessStr, color )
                let descriptionCell = Cell.text(j.description.text, VxColor.base())
                rows[j.creation.date.timeIntervalSince1970] = [completedCell, dateCell, listCell, timelinessCell, descriptionCell]
                
            }
            else if let t = item.getTask() {
                guard let completion = t.completion else {
                    print("Error missing completion for task: \(t)")
                    return
                }
                let completedCell = Cell.text(completion.date.daysAgo(), VxColor.base())
                let dateCell = Cell.text(VxdayUtil.dateFormatter.string(from: completion.date), VxColor.base())
                let emptyCell = Cell.empty
                let listCell = Cell.list(t.list)
                let descriptionCell = Cell.text(t.description.text, VxColor.base())
                rows[t.creation.date.timeIntervalSince1970] = [completedCell, dateCell, listCell, emptyCell, descriptionCell]
            }
            else if let n = item.getNow() {
                guard let completion = n.completion else {
                    print("Error missing completion for now : \(n)")
                    return
                }
                let completedCell = Cell.text(completion.date.daysAgo(), VxColor.base())
                let dateCell = Cell.text(VxdayUtil.dateFormatter.string(from: completion.date), VxColor.base())
                let emptyCell = Cell.empty
                let listCell = Cell.list(n.list)
                let descriptionCell = Cell.text(n.description.text, VxColor.base())
                rows[n.creation.date.timeIntervalSince1970] = [completedCell, dateCell, listCell, emptyCell, descriptionCell]
            }
        }
        
        let sortedKeys = Array(rows.keys).sorted(by: <)
        sortedKeys.forEach { key in
            table.addRow(rows[key]!)
        }
        return table
        
        //                strings.append("\(completed) \(timelinessStr) \(hash) \(list) \(d)")
    }
}


class ItemTableView {
    let items: [Item]
    init(_ item : Item) {
        items = [item]
    }
    init(_ items: [Item]) {
        self.items = items
    }

    func toTable(_ width: Int) -> VxdayTable {
        let sections = self.separate()
        
        let tasks = sections.tasks
        let overdue = sections.overdue
        let today = sections.today
        let upcoming = sections.upcoming
        let now  = sections.now
        let table = VxdayTable("", width: width)
        
        
        if tasks.count > 0 {
            table.addRow([Cell.info("Created"),Cell.info(""), Cell.info("Hash"), Cell.info("List")])
            tasks.forEach { task in
                let yyyymmddCell = Cell.text(VxdayUtil.dateFormatter.string(from: task.creation.date), VxColor.neutral())
                let hashCell = Cell.hash(task.hash)
                let listCell = Cell.list(task.list)
                let descCell = Cell.description(task.description)
                table.addRow([ yyyymmddCell, Cell.empty, hashCell, listCell, descCell])
            }

        }
        
        let hasDeadlined = upcoming.count > 0 || today.count > 0 || overdue.count > 0
        if hasDeadlined {
            table.addHeading("", char: "-", color: VxColor.base())
            table.addRow([Cell.info("Created"),Cell.info("Due")])//, Cell.info("Hash"), Cell.info("List"), Cell.info("Title")])
        }
        if overdue.count > 0 {
            table.addRow([Cell.empty])
            overdue.forEach { job in
                table.addRow(self.jobToCells(job, dateColor:  VxColor.danger()))
            }
        }
        if today.count > 0 {
            today.forEach { job in
                table.addRow(self.jobToCells(job, dateColor: VxColor.happy()))
            }
        }

        if upcoming.count > 0 {
            upcoming.forEach { job in
                table.addRow(self.jobToCells(job, dateColor:  VxColor.warning()))
            }
        }
        table.addRow([Cell.empty])
         // this looks alot like got what <list> might look like. Don't think I want it.
        table.addHeading("", char: "-", color: VxColor.base())
        
        if now.count > 0 {
           // table.addHeading("", char: "<>", color: VxColor.base())
            now.forEach { n in
                let yyyymmddCell = Cell.text(VxdayUtil.dateFormatter.string(from: n.creation.date), VxColor.bright())
                let hashCell = Cell.hash(n.hash)
                let listCell = Cell.list(n.list)
                let descCell = Cell.description(n.description)
                 table.addRow([yyyymmddCell, Cell.text("Now", VxColor.bright()), hashCell, listCell, descCell])
            }
            //table.addHeading("", char: "<>", color: VxColor.base())
            table.addHeading("", char: "-", color: VxColor.base())
        }   
        
        let totalCount = today.count + tasks.count + upcoming.count + overdue.count + now.count
        table.addRow([
            Cell.text("Overdue: \(overdue.count)", VxColor.white()),
            Cell.text("Today: \(today.count)", VxColor.white()),
            Cell.text("Upcoming: \(upcoming.count)", VxColor.white()),
            Cell.text("Now: \(now.count)", VxColor.white()),
            Cell.text("Total: \(totalCount)", VxColor.white())])
 
        return table
    }
    
    private func jobToCells(_ job: VxJob, dateColor: VxColor) -> [Cell] {
        let dueDate = job.deadline.date
        let daysAgoCell = Cell.text(dueDate.daysAgo(), dateColor)
        let yyyymmddCell = Cell.text(VxdayUtil.dateFormatter.string(from: job.creation.date), VxColor.base())
        let hashCell = Cell.hash(job.hash)
        let listCell = Cell.list(job.list)
        let descCell = Cell.description(job.description)
        return [yyyymmddCell, daysAgoCell,  hashCell, listCell, descCell]
    }
    
    private func separate() -> (tasks: [VxTask], overdue: [VxJob], today: [VxJob], upcoming: [VxJob], now: [VxNow]) {
        var tasks: [VxTask] = []
        var overdue: [VxJob] = []
        var today: [VxJob] = []
        var now: [VxNow] = []
        var upcoming: [VxJob] = []
        
        items.forEach { item in
            if let t = item.getTask() {
                tasks.append(t)
            }
            else if let j = item.getJob() {
                let deadline = j.deadline
                switch deadline.date.bucket() {
                    case .past:
                        overdue.append(j)
                    case .present:
                        today.append(j)
                    case .future:
                        upcoming.append(j)
                    }
            }
            else if let n = item.getNow() {
                now.append(n)
            }
        }
        return (tasks: tasks.sorted(by: {$0.creation.date < $1.creation.date}),
                overdue: overdue.sorted( by: {$0.deadline.date < $1.deadline.date}),
                today: today.sorted( by: {$0.deadline.date < $1.deadline.date}),
                upcoming: upcoming.sorted( by: {$0.deadline.date < $1.deadline.date}), now.sorted(by: {$0.creation.date < $1.creation.date}))
    }
    
    
    
}


class OneLinerView {
    static func showNewList(_ list: ListName) -> VxdayTable {
        let table = VxdayTable("", width: 150)
        let firstCell = Cell.text("New List Started:", VxColor.white())
        let secondCell = Cell.list(list)
        
        table.addRow([firstCell, secondCell])
        return table
    }
    
    static func showItemCreatedOneLiner(_ item: VxTask)-> VxdayTable {
        let list = Cell.list(item.list)
        let desc = Cell.description(item.description)
        let summary = Cell.text("Item added:", VxColor.white())
        let hashCell = Cell.hash(item.hash)
        let table = VxdayTable("", width: 150)
        table.addRow([summary, hashCell,list, desc])
        return table
        
    }
    static func showItemCreatedOneLiner(_ now: VxNow)-> VxdayTable {
        let list = Cell.list(now.list)
        let desc = Cell.description(now.description)
        let summary = Cell.text("Immediate Task added:", VxColor.bright())
        let hashCell = Cell.hash(now.hash)
        let table = VxdayTable("", width: 150)
        table.addRow([summary, hashCell,list, desc])
        return table
        
    }
    static func showItemCreatedOneLiner(_ item: VxJob)-> VxdayTable {
        let list = Cell.list(item.list)
        let desc = Cell.description(item.description)
        let summary = Cell.text("Item Added, Due:", VxColor.white())
        let deadline = Cell.deadline(item.deadline)
        let hashCell = Cell.hash(item.hash)
        let table = VxdayTable("", width: 150)
        table.addRow([ summary, deadline, hashCell, list, desc])
        return table
        
    }
    
    static func showHashRemoved(_ hash: Hash, list: ListName, description: Description) -> VxdayTable {
        let textCell = Cell.text("Deleted: ", VxColor.white())
        let hashCell = Cell.hash(hash)
        let listCell = Cell.list(list)
        let descCell = Cell.description(description)
        let table = VxdayTable("", width: 150)
        table.addRow([textCell, hashCell, listCell, descCell])
        return table
    }
    
    static func showHashCompleted(_ hash: Hash, list: ListName, description: Description) -> VxdayTable {
        let textCell = Cell.text("Finished! : ", VxColor.white())
        let hashCell = Cell.hash(hash)
        let listCell = Cell.list(list)
        let descCell = Cell.description(description)
        let table = VxdayTable("", width: 150)
        table.addRow([textCell, hashCell, listCell, descCell])
        return table
    }
    
    static func showTimerStopped(_ breakdown: TimeBreakdown) -> VxdayTable {
        let first = Cell.text("Timer stopped, total:", VxColor.white())
        let second = Cell.text(breakdown.toString(), VxColor.happy())
        let table = VxdayTable("", width: 150)
        table.addRow([first, second])
        return table
    }
    
    
    
    static func showTimerStarted(_ list: ListName, time: Date, hash: Hash, description: Description) -> VxdayTable {
        let list  = Cell.list(list)
        let desc = Cell.description(description)
        let summary = Cell.text("Started timer at", VxColor.white())
        let hash = Cell.hash(hash)
        let table = VxdayTable("", width: 150)
        let creation = CreationDate(time)
        let creationCell = Cell.text(creation.date.toTimeString(), VxColor.warning())
        table.addRow([summary, creationCell, list, hash, desc])
        return table
    }
}



class WhatView {
    let items: [Item]
    init(_ item : Item) {
        items = [item]
    }
    init(_ items: [Item]) {
        self.items = items
    }
    
    private func toBuckets() -> [ListSummary] {
        var dict : [ListName: ListSummary] = [:]
        for item in items {
            if let job = item.getJob() {
                let list = job.list
                if dict[list] == nil {
                    let summary = ListSummary(list)
                    summary.addJob(job)
                    dict[list] = summary
                }
                else  {
                    dict[list]?.addJob(job)
                }
            }
                
            else if let task = item.getTask() {
                let list = task.list
                if dict[list] == nil {
                    let summary =  ListSummary(list)
                    summary.addTask(task)
                    dict[list] = summary
                }
                else {
                    dict[list]?.addTask(task)
                }
                
            }
            else if let token = item.getToken() {
                let list = token.list
                if dict[list] == nil {
                    let summary =  ListSummary(list)
                    summary.addToken(token)
                    dict[list] = summary
                }
                else {
                    dict[list]?.addToken(token)
                }
                
            }
            else if let now = item.getNow() {
                let list = now.list
                if dict[list] == nil {
                    let summary = ListSummary(list)
                    summary.addNow(now)
                    dict[list] = summary
                }
            }
            //tokens aren't part of the summary yet.
        }
        return dict.map { return $0.value }.sorted( by: { $0.total() < $1.total()})
    }
    
    func toTable(_ width: Int) -> VxdayTable {

        let table = VxdayTable("All lists", width: width)
        let colWidth = 15
        let listHeading = Cell.info(VxdayUtil.pad("List", toLength: colWidth))
        let overdueHeading = Cell.info(VxdayUtil.pad("Overdue", toLength: colWidth))
        let todayHeading = Cell.info(VxdayUtil.pad("Due", toLength: colWidth))
        let upcomingHeading = Cell.info(VxdayUtil.pad("Upcoming", toLength: colWidth))
        //VX: now isnt finished for got what
        //let nowHeading = Cell.info(VxdayUtil.pad("Now", toLength: colWidth))
        let tasksHeading = Cell.info(VxdayUtil.pad("Tasks", toLength: colWidth))
        let totalHeading = Cell.info(VxdayUtil.pad("Total", toLength: colWidth))
        let buckets = self.toBuckets()

        let listCount = buckets.count
        let overdueCount = buckets.map { $0.past.count}.reduce(0, { $0 + $1})
        let todayCount = buckets.map { $0.present.count}.reduce(0, { $0 + $1})
        let futureCount = buckets.map { $0.future.count}.reduce(0 , {$0 + $1})
        let taskCount = buckets.map {$0.taskCount}.reduce(0, {$0 + $1})
        //let nowCount = buckets.map {$0.nowCount}.reduce(0, {$0 + $1})
      
	var headingRow: [Cell] = []
	headingRow.append(listHeading)

	let showOverdue = overdueCount > 0 
	let showToday = todayCount > 0
	let showFuture  = futureCount > 0 
	let showTasks = taskCount > 0
   // let showNow  = nowCount > 0
	if showOverdue {
		headingRow.append(overdueHeading)
	} 
	
	if showToday {
		headingRow.append(todayHeading)
	} 
	if showFuture {
		headingRow.append(upcomingHeading)
	} 
	if showTasks {
		headingRow.append(tasksHeading)
	}
        

	headingRow.append(totalHeading)
	headingRow.append(listHeading)
    table.addRow(headingRow)

        buckets.forEach { summary in
            let listCell = Cell.list(summary.list)
            let overdueCell = Cell.text(noStringForZero(summary.past.count), VxColor.danger())
            let presentCell = Cell.text(noStringForZero(summary.present.count), VxColor.warning())
            let futureCell = Cell.text(noStringForZero(summary.future.count), VxColor.happy())
            let taskCell = Cell.text(noStringForZero(summary.taskCount), VxColor.warning())
            let totalCell = Cell.text(noStringForZero(summary.past.count + summary.present.count + summary.future.count + summary.taskCount), VxColor.white())
            var bucketRow: [Cell] = []
            bucketRow.append(listCell)
            if showOverdue {
                bucketRow.append(overdueCell)
            }
            
            if showToday {
                bucketRow.append(presentCell)
            }
            if showFuture {
                bucketRow.append(futureCell)
            }
            if showTasks {
                bucketRow.append(taskCell)
            }

            bucketRow.append(totalCell)
            bucketRow.append(listCell)
                table.addRow(bucketRow)

        }
        
    table.addHeading("Total", char: "-", color: VxColor.base())
   
    let listCell = Cell.text(noStringForZero(listCount), VxColor.white())
    let overdueCell = Cell.text(noStringForZero(overdueCount), VxColor.danger())
    let todayCell = Cell.text(noStringForZero(todayCount), VxColor.warning())
    let futureCell = Cell.text(noStringForZero(futureCount), VxColor.happy())
    let taskCell = Cell.text(noStringForZero(taskCount), VxColor.warning())
    let totalCell = Cell.text(noStringForZero((overdueCount + todayCount + futureCount + taskCount)), VxColor.white())
	var summaryRow : [Cell] = []
	summaryRow.append(listCell)
	if showOverdue {
	   summaryRow.append(overdueCell)
	}
	if showToday {
	   summaryRow.append(todayCell)
	}
	if showFuture {
	   summaryRow.append(futureCell)
	}
	if showTasks {
	   summaryRow.append(taskCell)
	}
	summaryRow.append(totalCell)
	table.addRow(summaryRow)
        return table
        
    }

    private func noStringForZero(_ number: Int) -> String {
        if number == 0 {
            return ""
        }
        let str = "\(number)"
        return str
    }
    
}

class HelpView {
    
    static func toTable(_ width: Int) -> VxdayTable {
        let table = VxdayTable(" Got Help ", width: width)
        let c = VxColor.info2()
        let commands = ["to",
                        "it",
                        "till",
                        "jobs",
                        "what",
                        "start",
                        "done",
                        "remove",
                        "today"]
        let quickDescriptions = ["quickly keep an item",
                                 "add an item to a list",
                                 "add an item with a deadline to a list",
                                 "see everything",
                                 "see summaries of lists",
                                 "time an item, and take notes",
                                 "mark an item complete",
                                 "erase an item",
                                 "add an item to do today"]
        let explanations = ["The simplest thing you can add: create an item with no list, due to be completed today. For example: \(c.colorThis("'got it Try out Got'"))",
                            "Add an item to a list. For example: \(c.colorThis("'got to shop Strawberry icecream'")) creates a list called 'shop' and adds an item to it called: 'Strawberry Icecream'",
                            "Add an item with a deadline. There are 3 ways to do this. \(c.colorThis("'got till 5 read Grapes of Wrath'")) creates a deadline in 5 days time. \(c.colorThis("'got till 19th holiday book flights'")) creates a deadline either the 19th of this month, or next month if 19th has passed. \(c.colorThis("'got till 21/05/18 admin Email Bob about the thing'")) sets the deadline to 21st May 2018",
                            "Shows all active jobs. You can specify a list. For example: \(c.colorThis("'got jobs accounts'"))",
                            "",
                            "Starts the timer on an item. For example: \(c.colorThis("got start 0c441b2b0")) It will block this shell. You can add notes to this hash by writing into the shell with the timer. When you are finished, CTRL C or type \(c.colorThis("'stop'"))",
                            "\(c.colorThis("got done 0c441b2b0"))",
                            "\(c.colorThis("got remove 0c441b2b0"))",
            ""]

        let params = [
            "<item>",
            "<list> <item>",
            "[offset|nth|dd/mm/yy] <list> <item>",
            "[list]",
            "",
            "<hash>",
            "<hash>",
            "<hash>",
            "<list> <item>"
        ]
        table.addRow([Cell.info("Command"), Cell.info("Parameters"), Cell.info("Summary"), Cell.info("More")])
        commands.enumerated().forEach { (index, command) in
            let commandCell = Cell.text(command, VxColor.info2())
            let quick = Cell.description(Description(quickDescriptions[index]))
            let paramCell = Cell.text(params[index], VxColor.info())
            let explanation = Cell.description(Description(explanations[index]))
            table.addRow([commandCell, paramCell, quick, explanation])
        }
    
        
        return table
        
    }
}


