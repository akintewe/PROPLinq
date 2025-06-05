import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'base_view_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

/// Base View widget that provides common functionality for all Views
/// Automatically handles ViewModel integration and common UI patterns
abstract class BaseView<T extends BaseViewModel> extends StatefulWidget {
  const BaseView({super.key});

  /// Create the ViewModel instance
  T createViewModel();

  /// Build the UI - must be implemented by child classes
  Widget buildView(BuildContext context, T viewModel);

  /// Optional: Handle ViewModel initialization
  void onViewModelReady(T viewModel) {
    viewModel.initialize();
  }

  /// Optional: Show loading indicator
  Widget buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary600),
      ),
    );
  }

  /// Optional: Show error widget
  Widget buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error600,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.error,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.error600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.grey600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  State<BaseView<T>> createState() => _BaseViewState<T>();
}

class _BaseViewState<T extends BaseViewModel> extends State<BaseView<T>> {
  late T _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.createViewModel();
    widget.onViewModelReady(_viewModel);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<T>.value(
      value: _viewModel,
      child: Consumer<T>(
        builder: (context, viewModel, child) {
          // Show error if there's an error message
          if (viewModel.errorMessage != null) {
            return widget.buildErrorWidget(viewModel.errorMessage!);
          }

          // Show loading if loading and no other content
          if (viewModel.isLoading) {
            return widget.buildLoadingWidget();
          }

          // Build the main view
          return widget.buildView(context, viewModel);
        },
      ),
    );
  }
}

/// Simplified BaseView for basic stateless views
abstract class SimpleBaseView<T extends BaseViewModel> extends StatelessWidget {
  const SimpleBaseView({super.key});

  /// Create the ViewModel instance
  T createViewModel();

  /// Build the UI - must be implemented by child classes
  Widget buildView(BuildContext context, T viewModel);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<T>(
      create: (_) => createViewModel()..initialize(),
      child: Consumer<T>(
        builder: (context, viewModel, child) {
          return buildView(context, viewModel);
        },
      ),
    );
  }
} 