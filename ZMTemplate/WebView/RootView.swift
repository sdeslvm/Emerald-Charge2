//
//  RootView.swift
//  ZMTemplate
//

import SwiftUI

struct RootView: View {
    @StateObject var viewModel: RootViewModel
    @EnvironmentObject private var webCoordinator: WebViewCoordinator

    var body: some View {
            ZStack {
                Color.black
                content
            }
        .onAppear { viewModel.start() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            LoadingStateView()
        case .stub:
            StubStateView(message: viewModel.errorMessage ?? "Пока нечего показать.", retry: viewModel.retry)
        case .web(let url):
            WebShellView(url: url, hideNavigation: viewModel.isFallbackMode)
        case .failed:
            StubStateView(message: "Произошла ошибка. Попробуйте позже.", retry: viewModel.retry)
        }
    }

    private struct LoadingStateView: View {
        var body: some View {
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(.circular)
                Text("Loading…")
                    .foregroundColor(.white)
            }
        }
    }

    private struct StubStateView: View {
        let message: String
        let retry: () -> Void

        var body: some View {
            VStack(spacing: 24) {
                Text(message)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Button(action: retry) {
                    Text("Try again")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                }
            }
        }
    }

    private struct WebShellView: View {
        @EnvironmentObject private var webCoordinator: WebViewCoordinator
        let url: URL
        let hideNavigation: Bool
        
        var body: some View {
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    WebViewContainer(url: url)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
//                    if !hideNavigation {
//                        HStack {
//                            NavigationControls()
//                            Spacer()
//                        }
//                        .padding(.top, geometry.safeAreaInsets.top + 8)
//                        .padding(.horizontal, 12)
//                    }
                }
            }
        }
    }

    private struct NavigationControls: View {
        @EnvironmentObject private var webCoordinator: WebViewCoordinator

        var body: some View {
            HStack(spacing: 10) {
                NavButton(systemName: "chevron.backward", enabled: webCoordinator.canGoBack, action: webCoordinator.goBack)
                NavButton(systemName: "chevron.forward", enabled: webCoordinator.canGoForward, action: webCoordinator.goForward)
                if webCoordinator.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                }
            }
            .padding(8)
            .background(.ultraThinMaterial.opacity(0.6))
            .cornerRadius(12)
        }
    }

    private struct NavButton: View {
        let systemName: String
        let enabled: Bool
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Image(systemName: systemName)
                    .foregroundColor(enabled ? .white : .gray)
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 24, height: 24)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
            .disabled(!enabled)
        }
    }
}
