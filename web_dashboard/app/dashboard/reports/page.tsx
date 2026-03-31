"use client"

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { FileText, Download, Calendar, Filter, Printer } from "lucide-react"

const reports = [
  { id: 1, name: "User Activity Report", type: "Users", date: "2024-01-20", size: "245 KB" },
  { id: 2, name: "Map Usage Analytics", type: "Maps", date: "2024-01-19", size: "128 KB" },
  { id: 3, name: "Revenue Report", type: "Finance", date: "2024-01-18", size: "512 KB" },
  { id: 4, name: "System Performance", type: "System", date: "2024-01-17", size: "89 KB" },
  { id: 5, name: "Location Analytics", type: "Analytics", date: "2024-01-16", size: "320 KB" },
]

export default function ReportsPage() {
  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <h1 className="text-2xl sm:text-3xl font-bold tracking-tight">Reports</h1>
        <div className="flex flex-wrap gap-2">
          <Button variant="outline" className="w-full sm:w-auto"><Filter className="h-4 w-4 mr-2" />Filter</Button>
          <Button className="w-full sm:w-auto"><Download className="h-4 w-4 mr-2" />Export All</Button>
        </div>
      </div>

      <div className="grid gap-4 grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium">Total Reports</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">48</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium">This Week</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">12</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium">Downloads</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">1,284</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium">Avg Size</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">258 KB</div>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Recent Reports</CardTitle>
          <CardDescription>Your generated reports</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {reports.map((report) => (
              <div key={report.id} className="flex flex-col sm:flex-row sm:items-center sm:justify-between p-3 sm:p-4 border rounded-lg hover:bg-gray-50 transition-colors gap-3">
                <div className="flex items-center gap-3 sm:gap-4">
                  <div className="p-2 bg-primary/10 rounded-lg">
                    <FileText className="h-5 w-5 text-primary" />
                  </div>
                  <div>
                    <p className="font-medium text-sm sm:text-base">{report.name}</p>
                    <div className="flex flex-wrap items-center gap-2 sm:gap-3 text-xs sm:text-sm text-muted-foreground">
                      <span className="flex items-center gap-1"><Calendar className="h-3 w-3" />{report.date}</span>
                      <span>{report.size}</span>
                    </div>
                  </div>
                </div>
                <div className="flex items-center gap-2 ml-11 sm:ml-0">
                  <span className="px-2 py-1 text-xs bg-gray-100 rounded-full">{report.type}</span>
                  <Button variant="ghost" size="sm" className="h-8 w-8"><Download className="h-4 w-4" /></Button>
                  <Button variant="ghost" size="sm" className="h-8 w-8"><Printer className="h-4 w-4" /></Button>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
