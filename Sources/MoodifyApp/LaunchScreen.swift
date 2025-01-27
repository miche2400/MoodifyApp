//
//  LaunchScreen.swift
//  MoodifyApp
//
//  Created by Michelle Rodriguez on 27/01/2025.
//
import SwiftUI

struct LaunchScreen: View {
    var body: some View {
        ZStack {
            Color(.systemBackground) // Background color
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Display your logo
                Image("music logo design")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200) // Adjust size as needed
                
                Spacer()
                
                // Optional: Add app name or tagline
                Text("Moodify")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.primary)
                Text("Your Emotional DJ")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct LaunchScreen_Previews: PreviewProvider {
    static var previews: some View {
        LaunchScreen()
    }
}
