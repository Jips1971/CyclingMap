import SwiftUI
import CoreLocation
import UIKit

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var useMph = true
    @State private var directionUp = true

    private var speedString: String {
        let speedKmh = locationManager.speedKmh
        if useMph {
            let mph = speedKmh / 1.60934
            return String(format: "%.1f mph", mph)
        } else {
            return String(format: "%.1f km/h", speedKmh)
        }
    }

    private var distanceString: String {
        let meters = locationManager.distanceTravelled
        if useMph {
            let miles = meters / 1609.34
            return String(format: "Distance: %.2f mi", miles)
        } else {
            let km = meters / 1000
            return String(format: "Distance: %.2f km", km)
        }
    }

    var body: some View {
        ZStack {
            // MAP
            MapView(locationManager: locationManager, directionUp: directionUp)
                .edgesIgnoringSafeArea(.all)

            // TOP BAR (Reset + Direction toggle)
            VStack {
                HStack {
                    Button(action: {
                        locationManager.resetTrip()
                    }) {
                        Text("Reset Trip")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.red.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    Spacer()

                    Text(directionUp ? "Direction Up" : "North Up")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(8)
                        .background(.black.opacity(0.6))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .onTapGesture {
                            directionUp.toggle()
                        }
                }
                .padding(.top, 50)
                .padding(.horizontal, 20)

                Spacer()   // ← THIS keeps the top bar at the top
            }

            // BOTTOM HUD (Speed + Distance)
            VStack(spacing: 12) {

                // SPEED BAR
                Text(speedString)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 16)
                    .background(.black.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .onTapGesture {
                        useMph.toggle()
                    }

                // DISTANCE BAR
                Text(distanceString)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

            }
            .padding(.bottom, 40)   // ← THIS locks the HUD to the bottom
            .frame(maxHeight: .infinity, alignment: .bottom)
        
            .onAppear {
                    UIApplication.shared.isIdleTimerDisabled = true
                }
                .onDisappear {
                    UIApplication.shared.isIdleTimerDisabled = false
                }
            
        
        
        }
    }
}
