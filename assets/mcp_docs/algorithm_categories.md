# Algorithm Categories Reference

## Complete List of Available Categories

The Disting NT includes 44 algorithm categories organizing hundreds of algorithms:

### Audio Processing
- **Audio-IO** - Audio input/output utilities
- **Delay** - Echo, tape delay, ping-pong delay, reverse delay
- **Distortion** - Overdrive, fuzz, bit crusher, wave shaper
- **Dynamics** - Compression, gating, limiting, expansion
- **Effect** - General effects processing
- **EQ** - Equalization and tone shaping
- **Filter** - Low-pass, high-pass, band-pass, notch filters
- **Reverb** - Room, hall, plate, spring reverb algorithms

### Synthesis & Generation
- **Chiptune** - Retro 8-bit style sound generation
- **FM** - Frequency modulation synthesis
- **Granular** - Granular synthesis and processing
- **Noise** - White, pink, brown noise generation
- **Oscillator** - Basic waveform oscillators
- **Physical-Modeling** - Plucked string, resonator, modal synthesis
- **Polysynth** - Polyphonic synthesis capabilities
- **Resonator** - Resonant filters and physical modeling
- **Sampler** - Sample playback and manipulation
- **VCO** - Voltage-controlled oscillators
- **Vocoder** - Voice synthesis and vocoding effects
- **Waveshaper** - Waveshaping algorithms
- **Wavetable** - Wavetable synthesis

### Modulation & Control
- **CV** - Control voltage processing and utilities
- **Envelope** - Envelope generators (ADSR, complex envelopes)
- **LFO** - Low-frequency oscillators for modulation
- **Modulation** - Chorus, flanger, phaser, tremolo
- **Random** - Random voltage and stepped random generation
- **VCA** - Voltage-controlled amplifiers

### Sequencing & Timing
- **Clock** - Clock generation, division, multiplication
- **Rhythm** - Rhythm generators and timing utilities
- **Sequencer** - Step sequencers, Euclidean rhythms, Turing machine

### Utility & Processing
- **Convolution** - Convolution-based effects and processing
- **Logic** - Boolean logic, comparators, trigger processing
- **MIDI** - MIDI to CV, CV to MIDI, clock generation
- **Mixer** - Audio/CV mixing, crossfading, VCA functions
- **Pitch** - Pitch shifting, harmonization, tuning
- **Quantizer** - CV and MIDI quantization to scales
- **Routing** - Signal routing, switching, matrix mixing
- **Spectral** - FFT-based spectral processing
- **Tuning** - Tuning references and calibration
- **Utility** - General utility algorithms

### Specialized
- **Looper** - Real-time looping and recording
- **Scripting** - Lua scripting for custom algorithms
- **Source** - Signal sources and generators
- **Visualization** - Oscilloscope, tuner, analysis tools

## Usage in MCP Tools

### Filtering by Category
Use the `list_algorithms` tool with the `category` parameter:
```
list_algorithms(category="Filter")
list_algorithms(category="LFO") 
list_algorithms(category="Reverb")
```

### Category Search
Categories are also searchable with the `query` parameter:
```
list_algorithms(query="delay")      # Finds algorithms in Delay category
list_algorithms(query="modulation") # Finds Modulation category algorithms
```

### Multiple Categories
Many algorithms belong to multiple categories. For example:
- **Quantizer**: ["Pitch", "Utility", "CV"]
- **Looper**: ["Looper", "Sampler", "Effect"]
- **Vocoder**: ["Effect", "Vocoder"]

This categorization helps organize the extensive algorithm library for easier discovery and selection.