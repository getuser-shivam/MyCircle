// Core
export 'core/constants/app_constants.dart';
export 'core/theme/app_theme.dart';
export 'core/errors/app_exceptions.dart';
export 'core/extensions/string_extensions.dart';
export 'core/extensions/widget_extensions.dart';

// Models
export 'models/media_item.dart';
export 'models/social_user.dart';
export 'models/comment.dart';
export 'models/stream_model.dart';
export 'models/stream_chat_model.dart';
export 'models/stream_viewer_model.dart';
export 'models/dto.dart';
export 'models/ai_chat.dart';
export 'models/analytics.dart';
export 'models/user.dart';

// Repositories
export 'repositories/media_repository.dart';
export 'repositories/user_repository.dart';
export 'repositories/stream_repository.dart';
export 'repositories/auth_repository.dart';
export 'repositories/analytics_repository.dart';

// Providers (Consolidated)
export 'providers/auth_provider.dart';
export 'providers/media_provider.dart';
export 'providers/theme_provider.dart';
export 'providers/notification_provider.dart';
export 'providers/social_provider.dart';
export 'providers/social_graph_provider.dart';
export 'providers/comment_provider.dart';
export 'providers/subscription_provider.dart';
export 'providers/antigravity_provider.dart';
export 'providers/combined_providers.dart';
export 'providers/stream_provider.dart';
export 'providers/stream_chat_provider.dart';
export 'providers/stream_combined_provider.dart';
export 'providers/stream_provider_setup.dart';
export 'providers/desktop_provider.dart';
export 'providers/enhanced_media_provider.dart';
export 'providers/enhanced_auth_provider.dart';
export 'providers/enhanced_stream_provider.dart';
export 'providers/enhanced_social_provider.dart';
export 'providers/ai_chat_provider.dart';
export 'providers/analytics_provider.dart';
export 'providers/recommendation_provider.dart';
export 'providers/discovery_provider.dart';
export 'providers/provider_setup.dart';

// Services
export 'services/supabase_service.dart';
export 'services/ai_chat_service.dart';
export 'services/stream_service.dart';

// Screens - Home
export 'screens/home/home_screen.dart';
export 'screens/home/ultimate_home_screen.dart';

// Screens - Auth
export 'screens/auth/modern_onboarding_screen.dart';

// Screens - Media
export 'screens/media/discover_screen.dart';
export 'screens/media/media_detail_screen.dart';
export 'screens/media/upload_screen.dart';

// Screens - Premium
export 'screens/premium/subscription_tier_screen.dart';

// Screens - Discovery
export 'screens/discovery/premium_discovery_screen.dart';

// Screens - User
export 'screens/user/profile_screen.dart';
export 'screens/user/enhanced_profile_screen.dart';
export 'screens/user/notifications_screen.dart';
export 'screens/user/chat_screen.dart';

// Screens - Social
export 'screens/social/meet_me_screen.dart';
export 'screens/social/social_profile_screen.dart';

// Screens - AI Chat
export 'screens/ai_chat/ai_chat_home_screen.dart';
export 'screens/ai_chat/chat_screens.dart';
export 'screens/ai_chat/enhanced_chat_screen.dart';

// Screens - Analytics
export 'screens/analytics/creator_analytics_dashboard.dart';

// Screens - Dashboard
export 'screens/dashboard/enterprise_dashboard.dart';

// Screens - Desktop
export 'screens/desktop/desktop_settings_screen.dart';

// Screens - Search
export 'screens/search/search_screen.dart';
export 'screens/search/advanced_search_screen.dart';

// Screens - Streaming
export 'screens/streaming/stream_browse_screen.dart';
export 'screens/streaming/stream_player_screen.dart';
export 'screens/streaming/stream_setup_screen.dart';
export 'screens/streaming/stream_dashboard_screen.dart';

// Widgets - Common (Premium Glassmorphic Components)
export 'widgets/common/glassmorphic_container.dart';
export 'widgets/common/glassmorphic_card.dart';
export 'widgets/common/glassmorphic_card_enhanced.dart';
export 'widgets/common/glassmorphic_card_premium.dart';
export 'widgets/common/glassmorphic_button.dart';
export 'widgets/common/glassmorphic_dialog.dart';
export 'widgets/common/glassmorphic_text_field.dart';
export 'widgets/common/glassmorphic_list_tile.dart';
export 'widgets/common/glassmorphic_list_tile_premium.dart';
export 'widgets/common/glassmorphic_bottom_sheet.dart';
export 'widgets/common/glassmorphic_bottom_sheet_premium.dart';
export 'widgets/common/premium_animations.dart';
export 'widgets/common/premium_navigation_bar.dart';
export 'widgets/common/premium_floating_action_button.dart';
export 'widgets/common/premium_app_bar.dart';
export 'widgets/common/premium_loading_indicator.dart';
export 'widgets/common/search_bar.dart';
export 'widgets/common/connectivity_banner.dart';
export 'widgets/common/offline_banner.dart';
export 'widgets/common/content_guard.dart';
export 'widgets/common/ai_search_suggestions.dart';
export 'widgets/common/animations.dart';
export 'widgets/common/accessibility.dart';

// Widgets - Home
export 'widgets/home/premium_home_card.dart';
export 'widgets/home/trending_banner.dart';
export 'widgets/home/category_tabs.dart';

// Widgets - Media
export 'widgets/media/enhanced_media_card.dart';
export 'widgets/media/media_card.dart';
export 'widgets/media/media_player.dart';
export 'widgets/media/optimized_media_grid.dart';
export 'widgets/media/lazy_load_media_grid.dart';
export 'widgets/media/content_card.dart';
export 'widgets/media/category_chips.dart';

// Widgets - Navigation
export 'widgets/navigation/bottom_navigation_bar.dart';
export 'widgets/navigation/main_wrapper.dart';
export 'widgets/navigation/navigation_bar.dart';

// Widgets - Loading
export 'widgets/loading/shimmer_widget.dart';

// Widgets - Notifications
export 'widgets/notifications/notification_widget.dart';
export 'widgets/notifications/notification_card.dart';

// Widgets - Settings
export 'widgets/settings/theme_selector_widget.dart';

// Widgets - Social
export 'widgets/social/user_card_widget.dart';
export 'widgets/social/swipe_deck.dart';
export 'widgets/social/filter_bottom_sheet.dart';

// Widgets - Streaming
export 'widgets/streaming/stream_widget.dart';
export 'widgets/streaming/stream_card_widget.dart';
export 'widgets/streaming/stream_card_large.dart';

// Widgets - AI Chat
export 'widgets/ai_chat/ai_chat_widget_library.dart';
export 'widgets/ai_chat/ai_chat_widgets.dart';
export 'widgets/ai_chat/companion_avatar.dart';
export 'widgets/ai_chat/conversation_insights_panel.dart';
export 'widgets/ai_chat/glassmorphic_message_bubble.dart';
export 'widgets/ai_chat/multimodal_input.dart';
export 'widgets/ai_chat/smart_recommendation_card.dart';

// Widgets - Analytics
export 'widgets/analytics/analytics_overview_card.dart';
export 'widgets/analytics/content_performance_widget.dart';
export 'widgets/analytics/revenue_overview_widget.dart';

// Widgets - Enterprise
export 'widgets/enterprise/enterprise_widgets.dart';
export 'widgets/enterprise/premium_components.dart';

// Widgets - Feedback
export 'widgets/feedback/error_widget.dart';
export 'widgets/feedback/feedback_widget.dart';

// Widgets - Forms
export 'widgets/forms/enhanced_form_fields.dart';
export 'widgets/forms/search_form.dart';

// Widgets - Onboarding
export 'widgets/onboarding/onboarding_widgets.dart';

// Widgets - Discovery
export 'widgets/discovery/discovery_pulse_animation.dart';
export 'widgets/discovery/personalized_feed_widget.dart';
export 'widgets/discovery/smart_recommendation_card.dart';
export 'widgets/discovery/trending_discovery_widget.dart';

// Widgets - Desktop
export 'widgets/desktop/desktop_title_bar.dart';

// Utils
export 'utils/helpers.dart';
export 'utils/validators.dart';
export 'utils/formatters.dart';
export 'utils/constants.dart';

// Config
export 'supabase_options.dart';
