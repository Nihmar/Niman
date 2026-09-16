import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/transcription/transcription_job.dart';
import 'package:niman/src/transcription/transcription_model.dart';
import 'package:niman/src/ui/kinds/audio_transcript_placement.dart';

TranscriptionJob _job({
  String target = 'assets/a.wav',
  TranscriptPlacement placement = TranscriptPlacement.replace,
  String original = '',
  String text = 'dettato',
}) => TranscriptionJob(
  id: 1,
  notePath: 'note.md',
  clipTarget: target,
  audioPath: 'a.wav',
  model: transcriptionModelById('base')!,
  language: 'it',
  phase: TranscriptionPhase.done,
  placement: placement,
  originalDescription: original,
)..text = text;

void main() {
  const head = '---\ntype: audio\n---\n';

  test('an empty description is filled', () {
    final edit = placeTranscript('$head![](assets/a.wav)\n\nnota\n', _job())!;
    expect(edit.text, '$head![](assets/a.wav)\n> dettato\n\nnota\n');
    expect(edit.previous, '');
    expect(edit.written, 'dettato');
    expect(edit.keptEdits, false);
  });

  test('replace swaps the description it was asked over', () {
    final edit = placeTranscript(
      '$head![](assets/a.wav)\n> vecchia\n> riga\n',
      _job(original: 'vecchia\nriga'),
    )!;
    expect(edit.text, '$head![](assets/a.wav)\n> dettato\n');
    expect(edit.previous, 'vecchia\nriga');
  });

  test('replace keeps a description edited while it ran', () {
    final edit = placeTranscript(
      '$head![](assets/a.wav)\n> riscritta nel frattempo\n',
      _job(original: 'vecchia'),
    )!;
    expect(
      edit.text,
      '$head![](assets/a.wav)\n> riscritta nel frattempo\n> \n> dettato\n',
    );
    expect(edit.keptEdits, true);
  });

  test('append goes below the description', () {
    final edit = placeTranscript(
      '$head> Titolo\n![](assets/a.wav)\n> a mano\n',
      _job(placement: TranscriptPlacement.append, original: 'a mano'),
    )!;
    expect(
      edit.text,
      '$head> Titolo\n![](assets/a.wav)\n> a mano\n> \n> dettato\n',
    );
    expect(edit.written, 'a mano\n\ndettato');
  });

  test('only the clip of the job is touched', () {
    final edit = placeTranscript(
      '$head![](assets/a.wav)\n> uno\n\n![](assets/b.wav)\n> due\n',
      _job(target: 'assets/b.wav', original: 'due'),
    )!;
    expect(
      edit.text,
      '$head![](assets/a.wav)\n> uno\n\n![](assets/b.wav)\n> dettato\n',
    );
  });

  test('a clip no longer in the note gives nothing', () {
    expect(placeTranscript('$head![](assets/b.wav)\n', _job()), null);
  });
}
