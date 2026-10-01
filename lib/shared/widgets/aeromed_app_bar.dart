import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_metrics.dart';
import '../theme/app_text_styles.dart';

class AeroMedAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const AeroMedAppBar({
    super.key,
    required this.onMenuTap,
    required this.onNotificationsTap,
    required this.locationLabel,
    required this.userInitial,
    required this.onEmergencyTap,
    this.onUserTap,
  });

  final VoidCallback onMenuTap;

  final VoidCallback onNotificationsTap;

  final String locationLabel;

  final String userInitial;

  final VoidCallback onEmergencyTap;

  final VoidCallback? onUserTap;


  @override
  Size get preferredSize =>
      const Size.fromHeight(58);


  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,

      child: Container(
        width: double.infinity,

        height: 58,

        decoration: BoxDecoration(
          color:
              AppColors.surface.withValues( alpha: 0.96
          ),

          border: Border(
            bottom: BorderSide(
              color:
                  AppColors.outlineVariant
                      .withValues( alpha: 0.65
              ),
            ),
          ),
        ),

        child: SafeArea(
          bottom: false,

          child: Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
            ),

            child: Row(
              children: [

                // =================================================
                // MENU BUTTON
                // =================================================

                _TopIconButton(
                  icon:
                      Icons.menu_rounded,

                  tooltip:
                      'Open menu',

                  onTap:
                      onMenuTap,
                ),


                const SizedBox(
                  width: 7,
                ),


                // =================================================
                // AEROMED BRAND
                // =================================================

                Expanded(
                  child: Row(
                    children: [

                      // -------------------------------------------
                      // LOGO
                      // -------------------------------------------

                      Container(
                        width: 30,
                        height: 30,

                        decoration:
                            BoxDecoration(
                          color:
                              AppColors
                                  .surfaceContainer,

                          borderRadius:
                              BorderRadius.circular(
                            9,
                          ),

                          border:
                              Border.all(
                            color:
                                AppColors
                                    .outlineVariant,
                          ),

                          boxShadow:
                              softShadow(
                            color:
                                Colors.black,

                            opacity:
                                0.08,
                          ),
                        ),

                        child: const Center(
                          child: Icon(
                            Icons
                                .medical_services_rounded,

                            color:
                                AppColors.primary,

                            size: 17,
                          ),
                        ),
                      ),


                      const SizedBox(
                        width: 7,
                      ),


                      // -------------------------------------------
                      // BRAND
                      // -------------------------------------------

                      Flexible(
                        child: Row(
                          mainAxisSize:
                              MainAxisSize.min,

                          children: [

                            Flexible(
                              child: Text(
                                'Ambulance First',

                                maxLines: 1,

                                overflow:
                                    TextOverflow
                                        .ellipsis,

                                style:
                                    AppTextStyles
                                        .bodyStrong
                                        .copyWith(
                                  color:
                                      AppColors
                                          .primary,

                                  fontSize:
                                      12,

                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                            ),

                            const SizedBox(
                              width: 5,
                            ),

                            Container(
                              width: 3,
                              height: 3,

                              decoration:
                                  const BoxDecoration(
                                color:
                                    AppColors
                                        .outline,

                                shape:
                                    BoxShape.circle,
                              ),
                            ),

                            const SizedBox(
                              width: 5,
                            ),

                            Flexible(
                              child: Text(
                                locationLabel
                                    .toUpperCase(),

                                maxLines: 1,

                                overflow:
                                    TextOverflow
                                        .ellipsis,

                                style:
                                    AppTextStyles
                                        .labelSmall
                                        .copyWith(
                                  color:
                                      AppColors
                                          .textSecondary,

                                  fontSize:
                                      7,

                                  letterSpacing:
                                      0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),


                // =================================================
                // EMERGENCY / SOS
                // =================================================

                _EmergencyButton(
                  onTap:
                      onEmergencyTap,
                ),


                const SizedBox(
                  width: 6,
                ),


                // =================================================
                // PROFILE
                // =================================================

                _ProfileButton(
                  initial:
                      userInitial,

                  onTap:
                      onUserTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ===============================================================
// TOP ICON BUTTON
// ===============================================================

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;

  final String tooltip;

  final VoidCallback onTap;


  @override
  Widget build(
    BuildContext context,
  ) {
    return Tooltip(
      message:
          tooltip,

      child:
          Material(
        color:
            Colors.transparent,

        child:
            InkWell(
          onTap:
              onTap,

          borderRadius:
              BorderRadius.circular(
            10,
          ),

          child:
              SizedBox(
            width:
                34,

            height:
                34,

            child:
                Center(
              child:
                  Icon(
                icon,

                size:
                    19,

                color:
                    AppColors
                        .textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// ===============================================================
// EMERGENCY BUTTON
// ===============================================================

class _EmergencyButton extends StatelessWidget {
  const _EmergencyButton({
    required this.onTap,
  });

  final VoidCallback onTap;


  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          Colors.transparent,

      child:
          InkWell(
        onTap:
            onTap,

        borderRadius:
            BorderRadius.circular(
          AppRadius.pill,
        ),

        child:
            Container(
          width:
              34,

          height:
              34,

          decoration:
              BoxDecoration(
            color:
                AppColors.errorSoft,

            shape:
                BoxShape.circle,

            border:
                Border.all(
              color:
                  AppColors.error
                      .withValues(
                    alpha: 0.12
              ),
            ),
          ),

          child:
              const Center(
            child:
                Icon(
              Icons
                  .priority_high_rounded,

              size:
                  18,

              color:
                  AppColors.error,
            ),
          ),
        ),
      ),
    );
  }
}


// ===============================================================
// PROFILE BUTTON
// ===============================================================

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({
    required this.initial,
    required this.onTap,
  });

  final String initial;

  final VoidCallback? onTap;


  @override
  Widget build(
    BuildContext context,
  ) {
    return Tooltip(
      message:
          'Profile',

      child:
          Material(
        color:
            Colors.transparent,

        child:
            InkWell(
          onTap:
              onTap,

          borderRadius:
              BorderRadius.circular(
            99,
          ),

          child:
              AnimatedContainer(
            duration:
                const Duration(
              milliseconds: 180,
            ),

            width:
                36,

            height:
                36,

            decoration:
                BoxDecoration(
              color:
                  AppColors
                      .surfaceContainer,

              shape:
                  BoxShape.circle,

              border:
                  Border.all(
                color:
                    AppColors.primary,

                width:
                    1,
              ),

              boxShadow:
                  softShadow(
                color:
                    Colors.black,

                opacity:
                    0.08,
              ),
            ),

            child:
                Center(
              child:
                  Text(
                initial.isEmpty
                    ? 'K'
                    : initial
                        .substring(
                        0,
                        1,
                      )
                        .toUpperCase(),

                style:
                    AppTextStyles
                        .bodyStrong
                        .copyWith(
                  color:
                      AppColors.primary,

                  fontSize:
                      12,

                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}