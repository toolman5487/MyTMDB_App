import Foundation
import Combine

final class MovieVideoViewModel {
    
    @Published var videos: [MovieVideo] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let service: MovieVideoServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private let movieId: Int

    init(movieId: Int, service: MovieVideoServiceProtocol = MovieVideoService()) {
        self.movieId = movieId
        self.service = service
    }

    func fetchVideos() {
        isLoading = true
        print("Start fetching videos for movieId: \(movieId)")
        errorMessage = nil
        service.fetchVideos(movieId: movieId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                switch completion {
                case .finished:
                    print("Finished fetching videos for movieId: \(self.movieId)")
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] videos in
                print("Received \(videos.count) videos")
                self?.videos = videos
            }
            .store(in: &cancellables)
    }
}
