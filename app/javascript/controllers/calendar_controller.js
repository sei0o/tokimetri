import { Controller } from "@hotwired/stimulus"
import Calendar from "@toast-ui/calendar"

export default class extends Controller {
  static targets = [
    "calendar", 
    "currentDateRange", 
    "rawData", 
    "viewButton", 
    "toggleRawData"
  ]
  
  static values = {
    pages: Array,
    defaultView: { default: "day" }
  }

  static categoryColors = {
    '事務': '#4285F4',  // Blue
    '研究': '#0F9D58',  // Green
    '趣味': '#9C27B0',  // Purple
    'だらだら': '#9E9E9E',  // Gray
    '娯楽': '#FF9800',  // Orange
    '生活': '#009688',  // Teal
    '仕事': '#DB4437'   // Red
  }

  connect() {
    this.initCalendar()
   
    this.updateDateRangeText()
   
    this.setActiveViewButton(this.defaultViewValue)
  }

  initCalendar() {
    // Define calendar categories
    const calendarCategories = Object.entries(this.constructor.categoryColors).map(([name, color]) => ({
      id: name,
      name: name,
      backgroundColor: color,
      borderColor: color,
      dragBackgroundColor: color
    }))
    
    // Calendar options
    const options = {
      defaultView: this.defaultViewValue,
      useDetailPopup: true,
      useFormPopup: false,
      isReadOnly: true,
      week: {
        startDayOfWeek: 1,
        dayNames: ['日', '月', '火', '水', '木', '金', '土'],
        workweek: false,
        hourStart: 0,
        hourEnd: 24,
        taskView: false,
        eventView: ['time']
      },
      month: {
        dayNames: ['日', '月', '火', '水', '木', '金', '土'],
        startDayOfWeek: 1,
      },
      timezone: {
        zones: [
          {
            timezoneName: 'Asia/Tokyo',
            displayLabel: 'Tokyo',
          },
        ],
      },
      calendars: calendarCategories,
      template: {
        time: function(event) {
          return `<span style="font-weight: bold;">${event.title}</span>`
        },
        popupDetailDate: function(isAllday, start, end) {
          const startDate = new Date(start)
          const endDate = new Date(end)
          const startHour = startDate.getHours().toString().padStart(2, '0')
          const startMin = startDate.getMinutes().toString().padStart(2, '0')
          const endHour = endDate.getHours().toString().padStart(2, '0')
          const endMin = endDate.getMinutes().toString().padStart(2, '0')
          
          return `${startHour}:${startMin} - ${endHour}:${endMin}`
        }
      }
    }
    
    this.calendar = new Calendar(this.calendarTarget, options)
    
    this.loadEvents()
  }

  loadEvents() {
    const events = []
    const data = this.pagesValue || JSON.parse(this.element.dataset.pages)

    for (let page of data) {
      for (let line of page) {
        const [startTime, endTime, activity, category] = line
      
        // Skip entries with missing end time
        if (endTime === "_") continue
        if (startTime === "_") continue
        if (startTime === 'start') continue
      
        // Parse date and times for YYYY-MM-DD HH:MM format w/ regex
        const st = startTime.match(/(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})/)
        if (!st) continue
        const [startYear, startMonth, startDay, startHour, startMinute] = st.slice(1).map(Number)

        const et = endTime.match(/(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})/)
        if (!et) continue
        const [endYear, endMonth, endDay, endHour, endMinute] = et.slice(1).map(Number)

        const startDate = new Date(startYear, startMonth - 1, startDay, startHour, startMinute)
        const endDate = new Date(endYear, endMonth - 1, endDay, endHour, endMinute)
      
        // Get color based on category
        const categoryKey = category.trim()
        const color = this.constructor.categoryColors[categoryKey] || '#808080'
      
        // Create event object
        events.push({
          id: `${startDate}-${endDate}`,
          calendarId: categoryKey,
          title: activity,
          start: startDate,
          end: endDate,
          isAllday: false,
          category: 'time',
          backgroundColor: color,
          borderColor: color
        })
      }
    }

    this.calendar.createEvents(events)
  }

  // Actions
  changeView(event) {
    const viewName = event.currentTarget.dataset.view
    
    // Update active button
    this.viewButtonTargets.forEach(btn => btn.classList.remove('active'))
    event.currentTarget.classList.add('active')
    
    // Change calendar view
    this.calendar.changeView(viewName)
    this.updateDateRangeText()
  }
  
  prev() {
    this.calendar.prev()
    this.updateDateRangeText()
  }
  
  next() {
    this.calendar.next()
    this.updateDateRangeText()
  }
  
  today() {
    this.calendar.today()
    this.updateDateRangeText()
  }
  
  toggleRawData() {
    this.rawDataTarget.classList.toggle('visible')
  }
  
  // Helper methods
  updateDateRangeText() {
    const viewName = this.calendar.getViewName()
    const viewDate = this.calendar.getDate()
    
    const year = viewDate.getFullYear()
    const month = (viewDate.getMonth() + 1).toString().padStart(2, '0')
    const day = viewDate.getDate().toString().padStart(2, '0')
    
    if (viewName === 'day') {
      this.currentDateRangeTarget.textContent = `${year}年${month}月${day}日`
    } else if (viewName === 'week') {
      const weekStart = new Date(viewDate)
      const weekEnd = new Date(viewDate)
      const dayOfWeek = viewDate.getDay()
      const mondayOffset = dayOfWeek === 0 ? -6 : 1 - dayOfWeek
      
      weekStart.setDate(viewDate.getDate() + mondayOffset)
      weekEnd.setDate(weekStart.getDate() + 6)
      
      const startMonth = (weekStart.getMonth() + 1).toString().padStart(2, '0')
      const startDay = weekStart.getDate().toString().padStart(2, '0')
      const endMonth = (weekEnd.getMonth() + 1).toString().padStart(2, '0')
      const endDay = weekEnd.getDate().toString().padStart(2, '0')
      
      this.currentDateRangeTarget.textContent = `${weekStart.getFullYear()}年${startMonth}月${startDay}日 - ${endMonth}月${endDay}日`
    }
  }
  
  setActiveViewButton(viewName) {
    this.viewButtonTargets.forEach(btn => {
      if (btn.dataset.view === viewName) {
        btn.classList.add('active')
      } else {
        btn.classList.remove('active')
      }
    })
  }
}
