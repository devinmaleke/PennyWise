//
//  DateRangeButtonPickerView.swift
//  PennyWise
//
//  Created by Samir iOS on 21/01/26.
//

import SwiftUI

struct DateRangeButtonPickerView: View {

    @Binding var startDate: Date
    @Binding var endDate: Date

    @State private var showStartPicker = false
    @State private var showEndPicker = false

    var onApply: () -> Void
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            ZStack{
                Color.white.edgesIgnoringSafeArea(.all)
                VStack(spacing: 20) {
                    
                    dateButton(
                        title: "Start Date",
                        date: startDate
                    ) {
                        showStartPicker = true
                    }
                    
                    dateButton(
                        title: "End Date",
                        date: endDate
                    ) {
                        showEndPicker = true
                    }
                    
                    Spacer()
                }
                .padding()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Choose Date")
                            .foregroundColor(Color(hex: "1D2E3E"))
                            .bold()
                    }
                }
                .navigationBarItems(
                    leading: Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Text("Cancel")
                            .foregroundColor(Color.init(hex: "1D2E3E"))
                    }),
                    trailing: Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Text("Apply")
                            .foregroundColor(Color.init(hex: "1D2E3E"))
                    })
                )
                .sheet(isPresented: $showStartPicker) {
                    singleDatePicker(
                        title: "Start Date",
                        selection: $startDate,
                        maxDate: .today
                    )
                }
                .sheet(isPresented: $showEndPicker) {
                    singleDatePicker(
                        title: "End Date",
                        selection: $endDate,
                        minDate: startDate,
                        maxDate: endDate
                    )
                }
            }
        }
        .background(Color.red)
        .onChange(of: startDate) { newValue in
            if endDate < newValue {
                endDate = newValue
            }
        }
    }

    private func dateButton(
        title: String,
        date: Date,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(Color.init(hex: "466C85"))
                    .bold()
                Spacer()
                Text(date.formatted())
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            .shadow(radius: 1)
        }
    }

    private func singleDatePicker(
        title: String,
        selection: Binding<Date>,
        minDate: Date? = nil,
        maxDate: Date? = nil
    ) -> some View {
        VStack {
            Text(title)
                .font(.headline)
                .padding()

            if let min = minDate, let max = maxDate {
                DatePicker(
                    "",
                    selection: selection,
                    in: min...max,
                    displayedComponents: .date
                )
            } else if let max = maxDate {
                DatePicker(
                    "",
                    selection: selection,
                    in: ...max,
                    displayedComponents: .date
                )
            } else {
                DatePicker(
                    "",
                    selection: selection,
                    displayedComponents: .date
                )
            }

            Spacer()
        }
        .datePickerStyle(WheelDatePickerStyle())
        .padding()
    }



}
