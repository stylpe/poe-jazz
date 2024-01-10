$raw=Get-Content base.mid -Raw -AsByteStream
# Byte offsets in .mid file
$offset_instrument=0x7b
$offset_note1=0x7e
$offset_note2=0x82

filter Add-Number ([int]$n) { $_ + $n }
$scale_core = -2,0,3,4,6,7
$scale = $scale_core + ($scale_core | Add-Number 12) + ($scale_core | Add-Number 24) + ($scale_core | Add-Number 36)

New-Item out/jazz -ItemType Directory -Force

function gen([string]$name, [int]$instrument, $octave=4, $count = 20, $duration=0.5, $gain=1) {
    $basenote = 12 * ($octave + 1) # C4 = 60
    $notes = $scale | Add-Number $basenote | Select-Object -First $count
    $i=1
    foreach ($note in $notes) {
        $raw[$offset_instrument] = $instrument
        $raw[$offset_note1] = $note
        $raw[$offset_note2] = $note
        Set-Content gen.mid -AsByteStream -Value $raw
        &"C:\Users\mikal\Downloads\fluidsynth-2.3.4-win10-x64\bin\fluidsynth.exe" `
            -qn -O float -g $gain '.\GeneralUser GS v1.471.sf2' gen.mid -F gen.wav

        $subduration = $duration*0.1
        $filter = "afade=type=out:start_time={0:f3}:duration={1:f3}" -f ($duration-$subduration),$subduration
        $filename = "out/jazz/{0}-{1:00}.ogg" -f $name,$i++
        #&"C:\Users\mikal\bin\ffmpeg.exe" -v 0 -y -i gen.wav -af "$filter" -c:a pcm_f32le -flags +bitexact -t $duration $filename
        &"C:\Users\mikal\bin\ffmpeg.exe" -v 0 -y -i gen.wav -af "$filter" -t $duration $filename
        Get-Item $filename
    }
}

gen "piano" 1  # Cards
gen "glocken" 9 -octave 6 -duration 2 # Oils
gen "musicbox" 10 -octave 5 -duration 2 # Delirium
gen "organ" 17 -octave 4 # Map-like
gen "guitar" 26 -octave 3 # Maps
gen "bass" 33 -octave 2 # Map-like
gen "slapbass" 36 -octave 2 # Blighted
gen "hit" 55 -gain 1 # Uniques
gen "sax" 65 -octave 3 # Currency
gen "trumpet" 56 -octave 3 # misc special currency
gen "brass" 61 -octave 3 # misc special currency
gen "marimba" 12 # misc special currency
gen "steeldrum" 114 # misc special currency
gen "pluck" 45 # misc special currency

# Currency, Essence, Delve, Delirium, Oils, misc special currency
# Uniques (8), Cards (7), Maps (16 + variants), Map-like,
