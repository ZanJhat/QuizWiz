import 'dart:async';

import 'package:quizwiz/src/core/core.dart';
import 'package:quizwiz/src/features/cards/controller/controller.dart';
import 'package:quizwiz/src/features/cards/presentation/presentation.dart';
import 'package:quizwiz/src/core/services/collection_zip_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
            appBar: AppBar(
              title: const Text(AppStrings.homeScreen),
              actions: [
                IconButton(
                    tooltip: 'Nhập collection từ file ZIP (có thể nhập nhiều)',
                    onPressed: () => _importZip(context),
                    icon: const Icon(Icons.unarchive)),
                IconButton(
                    tooltip: 'Cài đặt',
                    onPressed: () =>
                        Navigator.of(context).pushNamed(Routes.settings),
                    icon: const Icon(Icons.settings_outlined)),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const CreateCollectionDialog()),
              child: const Icon(Icons.add),
            ),
            body: BlocBuilder<CardsBloc, CardsState>(
              builder: (context, state) {
                switch (state.collectionsRequestState) {
                  case RequestState.loading:
                    return const LoadingWidget();
                  case RequestState.error:
                    return CustomErrorWidget(
                      errorMessage: state.collectionsErrorMessage,
                    );
                  case RequestState.success:
                    return state.collections.isEmpty
                        ? const NoResultScreen(
                            description: AppStrings.noCollection)
                        : CollectionsListScreen(collections: state.collections);
                }
              },
            )));
  }
}

Future<void> _importZip(BuildContext context) async {
  try {
    final file = await CollectionZipService.pickZip();
    if (file == null || !context.mounted) return;
    final collections =
        await CollectionZipService.importCollectionsFromZip(file);
    if (!context.mounted) return;
    final completer = Completer<void>();
    context.read<CardsBloc>().add(
          ImportCollectionsEvent(
            collections: collections,
            completer: completer,
          ),
        );
    await completer.future;
    if (!context.mounted) return;
    customSnackBar(
      'Đã nhập ${collections.length} collection từ file ZIP',
      context,
    );
  } catch (error) {
    if (context.mounted) {
      customSnackBar('Nhập ZIP thất bại: $error', context);
    }
  }
}
