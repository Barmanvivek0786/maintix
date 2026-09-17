import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';
import '../../widgets/gps_enforcement_wrapper.dart';
import 'package:provider/provider.dart';
import './widgets/home_before_after_widget.dart';
import './widgets/home_cleaning_process_widget.dart';
import './widgets/home_contact_footer_widget.dart';
import './widgets/home_faqs_widget.dart';
import './widgets/home_header_widget.dart';
import './widgets/home_hero_banner_widget.dart';
import './widgets/home_services_widget.dart';
import './widgets/home_why_clean_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: GpsEnforcementWrapper(
        child: Scaffold(
          backgroundColor: AppTheme.background,
          // Do NOT use SafeArea here — HomeHeaderWidget handles it internally
          body: RefreshIndicator(
            onRefresh: () => context.read<AppState>().refreshAllData(
              refreshLocation: true,
            ),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(child: HomeHeaderWidget()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: HomeHeroBannerWidget(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: HomeBeforeAfterWidget(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: HomeWhyCleanWidget(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: HomeServicesWidget(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: HomeCleaningProcessWidget(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: HomeFaqsWidget(),
                  ),
                ),
                SliverToBoxAdapter(child: HomeContactFooterWidget()),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
