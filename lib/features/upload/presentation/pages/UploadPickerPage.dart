import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/uploadPickerCubit.dart';
import '../bloc/uploadPickerState.dart';
import '../widgets/SelectedAudioFileCard.dart';

class UploadPickerPage extends StatelessWidget {
  const UploadPickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio File Picker'),
      ),
      body: BlocConsumer<UploadPickerCubit, UploadPickerState>(
        listener: (context, state) {
          if (state.status == UploadPickerStatus.failure &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
              ),
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: state.status == UploadPickerStatus.loading
                      ? null
                      : () => context.read<UploadPickerCubit>().pickAudioFile(),
                  child: Text(
                    state.status == UploadPickerStatus.loading
                        ? 'Selecting...'
                        : 'Select MP3 / WAV',
                  ),
                ),
                const SizedBox(height: 16),
                if (state.pickedAudioFile != null) ...[
                  SelectedAudioFileCard(
                    pickedAudioFile: state.pickedAudioFile!,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () =>
                        context.read<UploadPickerCubit>().clearSelection(),
                    child: const Text('Clear'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
