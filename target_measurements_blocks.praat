# -----------------------------------------------
# Measurement extraction script
# Erik Morris, March 9, 2024
#
# Script assumes sound file and textgrid have the same name.
# TextGrid contains four tiers: word, vowel, target, voicing.
# Measures Fricative CoG, SD, Skewness, Kurtosis at midpoint and over the duration.
# Measures Stop VOT, duration, and burst spectral moments
# Measures Vowel formants F1,2,3 at onset of vowel
#
# Note to self: Stops durations are not converted to ms
# -----------------------------------------------

# Form to set up directory paths, configure tiers, set output file name
## Sounds and grids do not need to be in the same directory, however paths do all need to be specified
form: "Set Directories and Configuration"
	sentence: "sound_directory", "/Sounds"
	sentence: "textgrid_directory", "/TextGrids"
	comment: "Which tier contains voicing points?"
		natural: "voi_tier", "1"
	comment: "Which tier contains your target segments?"
		natural: "targ_tier", "2"
	comment: "Which tier contains your vowel labels?"
		natural: "vow_tier", "3"
	comment: "Which tier contains your word labels?"
		natural: "word_tier", "4"
	sentence: "output_directory", "/Data"
	comment: "What name should the output file have?"
		sentence: "results_name", "Output"
	optionmenu: "Separator_type", "2"
		option: "Tab"
		option: "Comma"
endform

# Error handling Step 1
# Make sure the paths contain final slashes to avoid issues (call procedure)
@cleanPath: sound_directory$
soundDir$ = "'cleanPath.out$'"
@cleanPath: textgrid_directory$
gridDir$ = "'cleanPath.out$'"
@cleanPath: output_directory$
outputDir$ = "'cleanPath.out$'"

# Error handling Step 2
# Checking if output file already exists and giving the option to keep or overwrite (call procedure)
@sepType
sep$ = sepType.is$
outFile$ = outputDir$ + results_name$ + sepType.ext$
if fileReadable: outFile$
	beginPause ("The output file already exists")
		comment ("Would you like to overwrite or append to the file?")
	overwrite = endPause ("Append", "Overwrite", 1)
	if overwrite = 2
		deleteFile: outFile$
		@createOutfile
	endif
else
	@createOutfile
endif ; File exists

# ------- Main Body --------


min_frequency = 0 ; 20 Hz TLM, 60 Hz AKG
max_frequency = 20000 ; This is the frequency response of the microphone of both the TLM and AKG

# Get audio file list from the first directory (sound)
Create Strings as file list: "list", "'soundDir$'*.wav"
nb_files = Get number of strings

# Start Main loop through all of the files found
# All is done in a single main loop because each tier has the same number of intervals
for lMain from 1 to nb_files
	select Strings list
	name_file$ = Get string: lMain

# Get speaker data from file name: AM1_date
	speaker$ = mid$ ("'name_file$'", 1, 4) ; Three chars starting position 1
	gen$ = mid$ ("'name_file$'", 2, 1) ; One char starting position 2

# Opens the sound file
	Read from file: "'soundDir$''name_file$'"
	name$ = selected$ ("Sound")
	orig_sound = selected ("Sound") ; ID of original sound file

# Open the corresponding textgrid
	Read from file: "'gridDir$''name$'.TextGrid"
	grid_name$ = selected$ ("TextGrid")

# Start looping through the intervals -----------------------
	nb_intervals = Get number of intervals: targ_tier
	for lInter from 1 to nb_intervals

# Find the fricatives (because there are also stops in there)
		selectObject: "TextGrid 'grid_name$'"
		targ_label$ = Get label of interval: targ_tier, lInter
		if targ_label$ = "x" or targ_label$ = "ɣ" or targ_label$ = "ç" or targ_label$ = "ʝ" or targ_label$ = "θ" or targ_label$ = "ð" or targ_label$ = "f" or targ_label$ = "v"
		# Fricative ---------------------------------------------
		# Durations and time stamps of the current fricative
			fEnd = Get end point: targ_tier, lInter
			fStart = Get starting point: targ_tier, lInter
			fDuration = (fEnd - fStart)
			fDuration_ms = fDuration * 1000
			fMid = fStart + (fDuration / 2)

			# Get the word it is in
			## Used to measure vowel formants by extracting the whole word
			word_interval = Get interval at time: word_tier, fStart
			word_label$ = Get label of interval: word_tier, word_interval ; lInter
			
		# Center of Gravity
		# Measures for the mean over duration and midpoint
		# Will need to set the min/max freq for the filter
			## Add a tiny buffer on either side
			threshold = fDuration*0.1
			domain_start = fStart - threshold
			domain_end = fEnd + threshold
			startBefore = fStart - 0.0128
			startAfter = fStart + 0.0128
			midBefore = fMid - 0.0128
			midAfter = fMid + 0.0128 ; This makes the 25.6 ms
			selectObject: orig_sound
			
			## Extract part with buffer
			Extract part: domain_start, domain_end, "Kaiser1", 1, "yes" ; Preserve times
			fric_part = selected ("Sound") ; ID of part
			
			# Whole ----------------
			# Resample 32kHz, filter 16kHz on the extracted part
			resampleFrequency = max_frequency * 2
			Resample: resampleFrequency, 50
			Filter (pass Hann band): min_frequency, max_frequency, 100

			To Spectrum: "no" ; Discrete
			Cepstral smoothing: 1000
			cogWhole = Get centre of gravity: 2 ; Power 2 = power spectrum
			sdevWhole = Get standard deviation: 2
			skewWhole = Get skewness: 2
			kurtWhole = Get kurtosis: 2

			# Start ----------------
			selectObject: orig_sound
			Extract part: startBefore, startAfter, "Kaiser1", 1, "yes" ; Preserve times

			resampleFrequency = max_frequency * 2
			Resample: resampleFrequency, 50
			Filter (pass Hann band): min_frequency, max_frequency, 100

			To Spectrum: "no" ; Discrete
			Cepstral smoothing: 1000
			cogWhole = Get centre of gravity: 2 ; Power 2 = power spectrum
			sdevWhole = Get standard deviation: 2
			skewWhole = Get skewness: 2
			kurtWhole = Get kurtosis: 2

			# Mid ----------------
			## Do this only if we do start and end as well
			selectObject: orig_sound
			Extract part: midBefore, midAfter, "Kaiser1", 1, "yes" ; Preserve times

			Resample: resampleFrequency, 50
			Filter (pass Hann band): min_frequency, max_frequency, 100

			To Spectrum: "no" ; Discrete
			Cepstral smoothing: 1000
			cogMid = Get centre of gravity: 2 ; Power 1 to get values in line with literature
			sdevMid = Get standard deviation: 2
			skewMid = Get skewness: 2
			kurtMid = Get kurtosis: 2

			# Call the vowel function, giving the fricative ending to target vowel start
			@vowelMeas: fEnd

			# Print to file
			appendFileLine: "'outFile$'", speaker$, sep$, targ_label$, sep$, cogWhole, sep$, sdevWhole, sep$, kurtWhole, sep$, skewWhole, sep$, cogMid, sep$, sdevMid, sep$, skewMid, sep$, kurtMid, sep$, fDuration_ms, sep$, vow_label$, sep$, vowelMeas.f1_on, sep$, vowelMeas.f2_on, sep$, vowelMeas.f3_on, sep$, vowelMeas.f1_mid, sep$, vowelMeas.f2_mid, sep$, vowelMeas.f3_mid, sep$, word_label$, sep$, "NA", sep$, "NA", sep$, "NA", sep$, block$
		elif targ_label$ = "k" or targ_label$ = "g" or targ_label$ = "c" or targ_label$ = "ɟ" or targ_label$ = "t" or targ_label$ = "d"
		# Stops ---------------------------------------------
			# Whole stop boundaries
			burstEnd = Get end point: targ_tier, lInter
			burstStart = Get starting point: targ_tier, lInter
			burstDuration = burstEnd - burstStart
			burstMid = burstStart + (burstDuration / 2)
			burstBefore = burstMid - 0.0128
			burstAfter = burstMid + 0.0128 ; 25.6 ms

			# Get the word it is in
			word_interval = Get interval at time: word_tier, burstStart
			wStart = Get starting point: word_tier, word_interval
			wEnd = Get end point: word_tier, word_interval
			word_label$ = Get label of interval: word_tier, word_interval ; lInter
			
			# Closure phase
			# End of the vowel in /po/ to the burst start
			closureDuration = burstStart - wStart

			# Overall duration
			# Start of word (end of vowel in /po/) to the start of the vowel after burst
			stopDuration = burstEnd - wStart

			# VOT = voicing_start - burst_start
			# negative if voicing occurs before burst, positive if it occurs after burst
			grid_part = Extract part: wStart, wEnd, "yes" ; Part of the grid
			num_points = Get number of points: voi_tier
			voicing_start = Get time of point: voi_tier, 1 ; because there should be only one
			stopVOT = voicing_start - burstStart

		# Burst phase --------------------------
			# Shape, spectral moments (same as frics), amplitude (energy) - max or mean over phase (intensity)
			# Measured the same way as the fricatives essentially
			## Extract part with buffer

			# Maybe this should be centered over the start of the burst - 10ms window (ala Nicolaidis 2019)
			selectObject: orig_sound
			Extract part: burstBefore, burstAfter, "Kaiser1", 1, "yes" ; Preserve times
			burst_part = selected ("Sound") ; ID of part
			
			# Resample 32kHz, filter 16kHz on the extracted part
			resampleFrequency = max_frequency * 2
			Resample: resampleFrequency, 50
			Filter (pass Hann band): min_frequency, max_frequency, 100

			To Spectrum: "yes"
			Cepstral smoothing: 1000
			cogBurst = Get centre of gravity: 2 ; Power 2 = power spectrum
			sdevBurst = Get standard deviation: 2
			skewBurst = Get skewness: 2
			kurtBurst = Get kurtosis: 2

			To Ltas (1-to-1)
			burstAmp = Get maximum: 750, 8000, "Parabolic" ; Range for stops
			
		# Call the vowel function, giving the stop ending to target vowel start
			@vowelMeas: burstEnd

		# Print to file
			appendFileLine: "'outFile$'", speaker$, sep$, targ_label$, sep$, cogBurst, sep$, sdevBurst, sep$, kurtBurst, sep$, skewBurst, sep$, "NA", sep$, "NA", sep$, "NA", sep$, "NA", sep$, burstDuration, sep$, vow_label$, sep$, vowelMeas.f1_on, sep$, vowelMeas.f2_on, sep$, vowelMeas.f3_on, sep$, vowelMeas.f1_mid, sep$, vowelMeas.f2_mid, sep$, vowelMeas.f3_mid, sep$, word_label$, sep$, closureDuration, sep$, stopVOT, sep$, burstAmp, sep$, block$
		elif targ_label$ = "0" or targ_label$ = "1" or targ_label$ = "2" or targ_label$ = "3" or targ_label$ = "4"
			# The interval immediately before the first word in a block is marked with the block number
			block$ = targ_label$
		endif ; Find target fricatives
	endfor ; Loop intervals on fricative tier

# Clean up created objects, but not the list of files
	select all
	minus Strings list
	Remove
endfor ; Main loop

# Clean up by removing the strings list now that we are done and inform user we are complete
select Strings list
Remove
clearinfo
writeInfoLine: "Finished, check results file."

# # # # # # # # # #
# #  Procedures # #
# # # # # # # # # #

# Check if the path string has a slash on the end, if not, add it and return
procedure cleanPath: .in$
	if not right$(.in$, 1) = "/"
		.out$ = "'.in$'" + "/"
	else
		.out$ = "'.in$'"
	endif
endproc

# Sets the type of separator and the extension for the output file
procedure sepType
	if separator_type = 1
		.is$ = tab$
		.ext$ = ".tsv"
	elif separator_type = 2
		.is$ = ","
		.ext$ = ".csv"
	endif
endproc

# Create the output file with header
procedure createOutfile
	appendFileLine: outFile$, "Speaker", sep$, "Consonant", sep$, "CoG (Hz)", sep$, "SD", sep$, "Kurtosis", sep$, "Skew", sep$, "CoG Mid (Hz)", sep$, "SD Mid", sep$, "Kurtosis Mid", sep$, "Skew Mid", sep$, "Fric/Burst Dur (ms)", sep$, "Vowel", sep$, "F1 Onset", sep$, "F2 Onset", sep$, "F3 Onset", sep$, "F1 Mid", sep$, "F2 Mid", sep$, "F3 Mid", sep$, "In Word", sep$, "Closure ms", sep$, "VOT ms", sep$, "Burst Max Amp (dB)", sep$, "Block"
endproc

# Take the vowel measurements
procedure vowelMeas: .start
		# Vowel ----------------------------------------------------
			# Gets the vowel interval and label based on the end of the fricative (specific to my griding)
			selectObject: "TextGrid 'grid_name$'"
			vow_interval = Get interval at time: vow_tier, .start
			vow_label$ = Get label of interval: vow_tier, vow_interval

			# Start of the vowel
			vStart = Get starting point: vow_tier, vow_interval
			vEnd = Get end point: vow_tier, vow_interval
			vDuration = (vEnd - vStart)
			vDuration_ms = vDuration * 1000
			vMid = vStart + (vDuration / 2)

			# Extract from the start of the word to the end of the vowel
			## This bypasses the issue with formant tracking errors
			partStart = Get starting point: word_tier, word_interval
			selectObject: orig_sound
			Extract part: partStart, vEnd, "Rectangular", 1, "yes"

		# Converting to formant object and tracking the first three formants
			if gen$ = "M"
				formant = noprogress To Formant (burg): 0.005, 5, 5000, 0.025, 50
				nbFormants = Get minimum number of formants
				if nbFormants >= 3
					formantTrack = noprogress Track: 3, 500, 1500, 2500, 3500, 4500, 1, 1, 1 ; Tracks F1-3
				else
					formantTrack = formant
				endif
			elsif gen$ = "F"
				formant = noprogress To Formant (burg): 0.005, 5, 5500, 0.025, 50
				nbFormants = Get minimum number of formants
				if nbFormants >= 3
					formantTrack = noprogress Track: 3, 550, 1650, 2750, 3850, 4950, 1, 1, 1
				else
					formantTrack = formant
				endif
			endif

		# Getting the values ----------------
			selectObject: formantTrack
			# Get the first three formant values at start and midpoint
			# accessed for printing via vowelMeas.f1_on etc
			.f1_on = Get value at time: 1, vStart, "Hertz", "Linear"
			.f2_on = Get value at time: 2, vStart, "Hertz", "Linear"
			.f3_on = Get value at time: 3, vStart, "Hertz", "Linear"
			.f1_mid = Get value at time: 1, vMid, "Hertz", "Linear"
			.f2_mid = Get value at time: 2, vMid, "Hertz", "Linear"
			.f3_mid = Get value at time: 3, vMid, "Hertz", "Linear"
endproc