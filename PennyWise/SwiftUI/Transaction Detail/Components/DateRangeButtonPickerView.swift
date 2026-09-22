//
//  DateRangeButtonPickerView.swift
//  PennyWise
//
//  Created by Devin Maleke on 21/01/26.
//

import SwiftUI

struct DateRangeButtonPickerView: View {

    @Binding var startDate: Date
    @Binding var endDate: Date
    var onApply: () -> Void

    @State private var draftStart: Date
    @State private var draftEnd: Date
    @State private var showStartPicker = false
    @State private var showEndPicker = false

    @Environment(\.presentationMode) private var presentationMode

    init(
        startDate: Binding<Date>,
        endDate: Binding<Date>,
        onApply: @escaping () -> Void
    ) {
        self._startDate = startDate
        self._endDate = endDate
        self.onApply = onApply
        self._draftStart = State(initialValue: startDate.wrappedValue)
        self._draftEnd = State(initialValue: endDate.wrappedValue)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.edgesIgnoringSafeArea(.all)
                VStack(spacing: 20) {
                    dateButton(
                        title: "Start Date",
                        date: draftStart
                    ) {
                        showStartPicker = true
                    }

                    dateButton(
                        title: "End Date",
                        date: draftEnd
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
                            .foregroundColor(Color.appInk)
                            .bold()
                    }
                }
                .navigationBarItems(
                    leading: Button(action: cancel, label: {
                        Text("Cancel")
                            .foregroundColor(Color.appInk)
                    }),
                    trailing: Button(action: apply, label: {
                        Text("Apply")
                            .foregroundColor(Color.appInk)
                    })
                )
                .sheet(isPresented: $showStartPicker) {
                    singleDatePicker(
                        title: "Start Date",
                        selection: $draftStart,
                        maxDate: Date()
                    )
                }
                .sheet(isPresented: $showEndPicker) {
                    singleDatePicker(
                        title: "End Date",
                        selection: $draftEnd,
                        minDate: draftStart,
                        maxDate: Date()
                    )
                }
            }
        }
        .onChange(of: draftStart) { newValue in
            if draftEnd < newValue {
                draftEnd = newValue
            }
        }
    }

    private func cancel() {
        presentationMode.wrappedValue.dismiss()
    }

    private func apply() {
        startDate = draftStart
        endDate = max(draftEnd, draftStart)
        onApply()
        presentationMode.wrappedValue.dismiss()
    }

    private func dateButton(
        title: String,
        date: Date,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(Color.appMuted)
                    .bold()
                Spacer()
                Text(date.formatted())
                    .foregroundColor(Color.appInk)
            }
            .padding()
            .background(Color.appCard)
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

            if let min = minDate, let max = maxDate, min <= max {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .foregroundColor(Color.appInk)
    }
}
