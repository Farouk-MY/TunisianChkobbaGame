#!/bin/bash

# 🎴 CHKOBBA - Complete Folder Structure Creation Script
# Run this from your project root directory

echo "🎴 Creating Chkobba Clean Architecture Folder Structure..."

# Core folders
mkdir -p lib/core/constants
mkdir -p lib/core/theme
mkdir -p lib/core/errors
mkdir -p lib/core/utils
mkdir -p lib/core/services

# Game Feature (Main Feature)
mkdir -p lib/features/game/domain/entities
mkdir -p lib/features/game/domain/repositories
mkdir -p lib/features/game/domain/usecases
mkdir -p lib/features/game/data/models
mkdir -p lib/features/game/data/datasources
mkdir -p lib/features/game/data/repositories
mkdir -p lib/features/game/presentation/providers
mkdir -p lib/features/game/presentation/pages
mkdir -p lib/features/game/presentation/widgets/game_board
mkdir -p lib/features/game/presentation/widgets/cards

# AI Feature
mkdir -p lib/features/ai/domain/repositories
mkdir -p lib/features/ai/domain/usecases
mkdir -p lib/features/ai/data/models
mkdir -p lib/features/ai/data/repositories
mkdir -p lib/features/ai/ai_engine

# Multiplayer Feature
mkdir -p lib/features/multiplayer/domain/entities
mkdir -p lib/features/multiplayer/domain/repositories
mkdir -p lib/features/multiplayer/domain/usecases
mkdir -p lib/features/multiplayer/data/models
mkdir -p lib/features/multiplayer/data/datasources
mkdir -p lib/features/multiplayer/data/repositories
mkdir -p lib/features/multiplayer/presentation/pages
mkdir -p lib/features/multiplayer/presentation/widgets

# Auth Feature
mkdir -p lib/features/auth/domain/entities
mkdir -p lib/features/auth/domain/repositories
mkdir -p lib/features/auth/domain/usecases
mkdir -p lib/features/auth/data/models
mkdir -p lib/features/auth/data/datasources
mkdir -p lib/features/auth/data/repositories
mkdir -p lib/features/auth/presentation/providers
mkdir -p lib/features/auth/presentation/pages
mkdir -p lib/features/auth/presentation/widgets

# Home Feature
mkdir -p lib/features/home/presentation/pages
mkdir -p lib/features/home/presentation/widgets

# Splash Feature
mkdir -p lib/features/splash/presentation/pages
mkdir -p lib/features/splash/presentation/widgets

# Shared Components
mkdir -p lib/shared/widgets/animated
mkdir -p lib/shared/widgets/buttons
mkdir -p lib/shared/widgets/loading

echo "✅ All folders created successfully!"
echo ""
echo "📁 Folder structure:"
echo "   - core/ (constants, theme, errors, utils, services)"
echo "   - features/game/ (domain, data, presentation)"
echo "   - features/ai/ (domain, data, ai_engine)"
echo "   - features/multiplayer/ (domain, data, presentation)"
echo "   - features/auth/ (domain, data, presentation)"
echo "   - features/home/ (presentation)"
echo "   - features/splash/ (presentation)"
echo "   - shared/widgets/ (animated, buttons, loading)"
echo ""
echo "🚀 Ready to start coding!"
echo "📝 Next: Run the commands below to verify structure"
