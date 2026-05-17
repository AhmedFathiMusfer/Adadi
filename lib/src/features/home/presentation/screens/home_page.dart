import 'package:adadi/src/imports/core_imports.dart';
import 'package:adadi/src/imports/packages_imports.dart';

import 'package:adadi/src/features/auth/presentation/providers/session_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final session = ref.watch(sessionProvider);
    final user = session.user;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppTopBar(
        title: 'home.home_title'.tr(),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppIcon(
                icon: IconsaxPlusLinear.home,
                size: 60.sp,
                color: colorScheme.primary,
              ),
              SizedBox(height: AppSpacing.lg.h),
              Text(
                user?.name ?? user?.email ?? ('home.welcome_home'.tr()),
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                  fontSize: 28.sp,
                ),
              ),
              SizedBox(height: AppSpacing.md.h),
              Text(
                user != null && user.name != null
                    ? user.email
                    : ('home.home_subtitle'.tr()),
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: AppSpacing.xl.h),
              FilledButton.icon(
                onPressed: () => context.push(AppRoutes.apartments),
                icon: const Icon(Icons.apartment),
                label: const Text('إدارة الشقق'),
              ),
              SizedBox(height: AppSpacing.sm.h),
              FilledButton.tonalIcon(
                onPressed: () => context.push(AppRoutes.invoices),
                icon: const Icon(Icons.receipt_long),
                label: const Text('الفواتير والمسح الذكي'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
