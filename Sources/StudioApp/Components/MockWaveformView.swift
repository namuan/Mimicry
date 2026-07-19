import SwiftUI

/// Renders a mock waveform from audio data by sampling amplitude values.
struct MockWaveformView: View {
    let data: Data
    let barCount: Int = 60

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 1) {
                ForEach(0..<barCount, id: \.self) { i in
                    let height = sampleHeight(at: i, totalWidth: geometry.size.width)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.accentColor.opacity(0.6))
                        .frame(width: max(1, geometry.size.width / CGFloat(barCount) - 1))
                        .frame(height: max(2, height * geometry.size.height))
                }
            }
        }
    }

    private func sampleHeight(at index: Int, totalWidth: CGFloat) -> CGFloat {
        guard data.count > 44 else { return CGFloat.random(in: 0.3...0.8) } // WAV header is 44 bytes

        let audioData = data.dropFirst(44)
        let samples = audioData.count / 2 // 16-bit

        guard samples > 0 else { return 0.3 }

        // Sample several points in this bar's region
        let regionSize = max(1, samples / barCount)
        let start = index * regionSize
        var maxAmplitude: Int16 = 0

        for offset in 0..<min(regionSize, samples - start - 1) {
            let byteIndex = (start + offset) * 2
            guard byteIndex + 1 < audioData.count else { break }
            let sample = Int16(audioData[audioData.startIndex + byteIndex]) |
                (Int16(audioData[audioData.startIndex + byteIndex + 1]) << 8)
            if abs(Int(sample)) > abs(Int(maxAmplitude)) {
                maxAmplitude = sample
            }
        }

        let normalized = min(1.0, Double(abs(maxAmplitude)) / Double(Int16.max / 4))
        return CGFloat(max(0.05, normalized))
    }
}
