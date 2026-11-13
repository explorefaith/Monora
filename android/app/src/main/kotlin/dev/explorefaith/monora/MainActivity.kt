package dev.explorefaith.monora

import com.ryanheise.audioservice.AudioServiceActivity

/// Required by just_audio_background (§5) so background playback and the
/// media notification work.
class MainActivity : AudioServiceActivity()
