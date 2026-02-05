import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/faq.dart';
import '../../services/support_service.dart';
import '../../theme/app_theme.dart';
import 'contact_support_screen.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final SupportService _supportService = SupportService.instance;
  final TextEditingController _searchController = TextEditingController();
  List<FAQ> _filteredFAQs = FAQ.defaultFAQs;
  String? _expandedCategory;
  Set<String> _expandedQuestions = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredFAQs = _supportService.searchFAQs(query);
      // Expand all categories when searching
      if (query.isNotEmpty) {
        _expandedCategory = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = _filteredFAQs.map((f) => f.category).toSet().toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Help Center'),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for help...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.textHint),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  borderSide: const BorderSide(color: AppTheme.primaryGreen),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                  vertical: AppTheme.spacingS,
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              children: [
                // Quick actions
                _buildQuickActions(),
                const SizedBox(height: AppTheme.spacingL),

                // FAQs by category
                if (_searchController.text.isNotEmpty) ...[
                  // Show flat list when searching
                  _buildSearchResults(),
                ] else ...[
                  // Show categorized FAQs
                  const Text(
                    'Frequently Asked Questions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  ...categories.map((category) => _buildCategorySection(category)),
                ],

                const SizedBox(height: AppTheme.spacingL),

                // Still need help?
                _buildContactCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.email_outlined,
            label: 'Email Us',
            onTap: () => _launchEmail(),
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.phone_outlined,
            label: 'Call Us',
            onTap: () => _launchPhone(),
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.support_agent,
            label: 'Contact',
            onTap: () => _navigateToContactSupport(),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryGreen, size: 28),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(String category) {
    final isExpanded = _expandedCategory == category;
    final faqs = FAQ.getFAQsByCategory(category);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Category header
          InkWell(
            onTap: () {
              setState(() {
                _expandedCategory = isExpanded ? null : category;
              });
            },
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingS),
                    decoration: BoxDecoration(
                      color: AppTheme.iconBackground,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${faqs.length} questions',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          // FAQ items
          if (isExpanded)
            ...faqs.map((faq) => _buildFAQItem(faq)),
        ],
      ),
    );
  }

  Widget _buildFAQItem(FAQ faq) {
    final isExpanded = _expandedQuestions.contains(faq.id);

    return Column(
      children: [
        const Divider(height: 1),
        InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedQuestions.remove(faq.id);
              } else {
                _expandedQuestions.add(faq.id);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        faq.question,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.remove : Icons.add,
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    faq.answer,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_filteredFAQs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                'No results found',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                'Try different keywords or contact support',
                style: TextStyle(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_filteredFAQs.length} result${_filteredFAQs.length != 1 ? 's' : ''} found',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: _filteredFAQs
                .asMap()
                .entries
                .map((entry) => Column(
                      children: [
                        if (entry.key > 0) const Divider(height: 1),
                        _buildFAQItem(entry.value),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildContactCard() {
    final contact = _supportService.getSupportContact();

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.primaryGreenDark],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.help_outline, color: Colors.white, size: 24),
              SizedBox(width: AppTheme.spacingS),
              Text(
                'Still need help?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Our support team is available ${contact['hours']}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _navigateToContactSupport,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryGreen,
              ),
              child: const Text('Contact Support'),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Getting Started':
        return Icons.rocket_launch;
      case 'Deliveries':
        return Icons.local_shipping;
      case 'Earnings':
        return Icons.attach_money;
      case 'Account':
        return Icons.person;
      case 'Troubleshooting':
        return Icons.build;
      default:
        return Icons.help;
    }
  }

  Future<void> _launchEmail() async {
    final contact = _supportService.getSupportContact();
    final uri = Uri.parse('mailto:${contact['email']}?subject=Driver App Support');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchPhone() async {
    final contact = _supportService.getSupportContact();
    final uri = Uri.parse('tel:${contact['phone']}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _navigateToContactSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ContactSupportScreen()),
    );
  }
}
