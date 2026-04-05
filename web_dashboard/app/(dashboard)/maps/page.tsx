"use client"

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { MapPin, Plus, RefreshCw, Layers } from "lucide-react"

export default function MapsPage() {
  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <h1 className="text-2xl sm:text-3xl font-bold tracking-tight">Maps Management</h1>
        <div className="flex flex-wrap gap-2">
          <Button variant="outline" className="w-full sm:w-auto"><RefreshCw className="h-4 w-4 mr-2" />Refresh</Button>
          <Button className="w-full sm:w-auto"><Plus className="h-4 w-4 mr-2" />New Map</Button>
        </div>
      </div>

      <div className="grid gap-4 grid-cols-1 sm:grid-cols-3">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">Total Maps</CardTitle>
            <MapPin className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">156</div>
            <p className="text-xs text-muted-foreground">Active map instances</p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">Markers</CardTitle>
            <MapPin className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">2,341</div>
            <p className="text-xs text-muted-foreground">Total map markers</p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium">Zones</CardTitle>
            <Layers className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">48</div>
            <p className="text-xs text-muted-foreground">Active geo-zones</p>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Map Preview</CardTitle>
          <CardDescription>Interactive map view</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="h-[300px] sm:h-[400px] md:h-[500px] bg-gray-100 rounded-lg flex items-center justify-center">
            <div className="text-center text-gray-500 p-4">
              <MapPin className="h-10 w-10 sm:h-12 mx-auto mb-4" />
              <p className="text-sm sm:text-base">Interactive map will render here</p>
              <p className="text-xs sm:text-sm">Connect to map tile provider for live view</p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
