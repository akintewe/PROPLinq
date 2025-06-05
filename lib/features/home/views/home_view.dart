import 'package:flutter/material.dart';
import '../../../core/base/base_view.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_input_field.dart';
import '../view_models/home_view_model.dart';
import '../models/property_model.dart';

class HomeView extends BaseView<HomeViewModel> {
  const HomeView({super.key});

  @override
  HomeViewModel createViewModel() => HomeViewModel();

  @override
  Widget buildView(BuildContext context, HomeViewModel viewModel) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.appName,
          style: AppTypography.propLinqLogo,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: viewModel.refresh,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: AppDimensions.spacing24),
              _buildSearchSection(viewModel),
              const SizedBox(height: AppDimensions.spacing24),
              _buildFeaturedSection(viewModel),
              const SizedBox(height: AppDimensions.spacing24),
              _buildAllPropertiesSection(viewModel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.welcomeToPropLinq,
          style: AppTypography.h3,
        ),
        const SizedBox(height: AppDimensions.spacing8),
        Text(
          AppStrings.findYourDreamProperty,
          style: AppTypography.propLinqTagline,
        ),
      ],
    );
  }

  Widget _buildSearchSection(HomeViewModel viewModel) {
    return AppSearchField(
      hintText: AppStrings.searchPlaceholder,
      onChanged: viewModel.updateSearchQuery,
    );
  }

  Widget _buildFeaturedSection(HomeViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.featuredProperties,
              style: AppTypography.h5,
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacing16),
        SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: viewModel.featuredProperties.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppDimensions.spacing16),
            itemBuilder: (context, index) {
              final property = viewModel.featuredProperties[index];
              return _buildFeaturedPropertyCard(property, viewModel);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedPropertyCard(PropertyModel property, HomeViewModel viewModel) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey900.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Image
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.grey200,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.radiusL),
                topRight: Radius.circular(AppDimensions.radiusL),
              ),
            ),
            child: Stack(
              children: [
                // Placeholder for image
                Center(
                  child: Icon(
                    Icons.home,
                    size: 48,
                    color: AppColors.grey500,
                  ),
                ),
                // Favorite button
                Positioned(
                  top: AppDimensions.paddingS,
                  right: AppDimensions.paddingS,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        property.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: property.isFavorite ? AppColors.error600 : AppColors.grey600,
                      ),
                      onPressed: () => viewModel.toggleFavorite(property.id),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Property Details
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.title,
                  style: AppTypography.h6,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimensions.spacing4),
                Text(
                  property.address,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.grey600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimensions.spacing8),
                Row(
                  children: [
                    _buildPropertyFeature(Icons.bed, '${property.bedrooms}'),
                    const SizedBox(width: AppDimensions.spacing12),
                    _buildPropertyFeature(Icons.bathtub, '${property.bathrooms}'),
                    const SizedBox(width: AppDimensions.spacing12),
                    _buildPropertyFeature(Icons.square_foot, property.formattedArea),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacing8),
                Text(
                  property.formattedPrice,
                  style: AppTypography.h6.copyWith(
                    color: AppColors.primary600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: AppDimensions.iconS,
          color: AppColors.grey600,
        ),
        const SizedBox(width: AppDimensions.spacing4),
        Text(
          text,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.grey600,
          ),
        ),
      ],
    );
  }

  Widget _buildAllPropertiesSection(HomeViewModel viewModel) {
    final properties = viewModel.filteredProperties;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Properties',
          style: AppTypography.h5,
        ),
        const SizedBox(height: AppDimensions.spacing16),
        if (properties.isEmpty)
          _buildEmptyState()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: properties.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppDimensions.spacing16),
            itemBuilder: (context, index) {
              final property = properties[index];
              return _buildPropertyListItem(property, viewModel);
            },
          ),
      ],
    );
  }

  Widget _buildPropertyListItem(PropertyModel property, HomeViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.grey200,
          width: AppDimensions.borderThin,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppDimensions.paddingM),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.grey200,
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Icon(
            Icons.home,
            color: AppColors.grey500,
          ),
        ),
        title: Text(
          property.title,
          style: AppTypography.labelLarge,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppDimensions.spacing4),
            Text(
              property.address,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.grey600,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing8),
            Row(
              children: [
                _buildPropertyFeature(Icons.bed, '${property.bedrooms}'),
                const SizedBox(width: AppDimensions.spacing12),
                _buildPropertyFeature(Icons.bathtub, '${property.bathrooms}'),
              ],
            ),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(
                property.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: property.isFavorite ? AppColors.error600 : AppColors.grey600,
              ),
              onPressed: () => viewModel.toggleFavorite(property.id),
            ),
            Text(
              property.formattedPrice,
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.primary600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        onTap: () {
          // Navigate to property details
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.grey400,
            ),
            const SizedBox(height: AppDimensions.spacing16),
            Text(
              AppStrings.noResults,
              style: AppTypography.h6.copyWith(
                color: AppColors.grey600,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing8),
            Text(
              'Try adjusting your search criteria',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 