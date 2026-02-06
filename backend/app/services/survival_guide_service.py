"""
Survival guide service for managing survival guides
"""

from typing import List, Optional
from datetime import datetime
from app.models.survival_guide import SurvivalGuide, SurvivalStep


class SurvivalGuideService:
    def __init__(self):
        # Pre-defined survival guides
        self._guides = self._get_default_guides()

    def get_all_guides(self) -> List[SurvivalGuide]:
        """Get all survival guides"""
        return self._guides

    def get_guide_by_id(self, guide_id: str) -> Optional[SurvivalGuide]:
        """Get a specific survival guide by ID"""
        for guide in self._guides:
            if guide.id == guide_id:
                return guide
        return None

    def get_guides_by_category(self, category: str) -> List[SurvivalGuide]:
        """Get survival guides by category"""
        return [g for g in self._guides if g.category.lower() == category.lower()]

    def _get_default_guides(self) -> List[SurvivalGuide]:
        """Return default survival guides"""
        return [
            SurvivalGuide(
                id="earthquake_guide",
                title="Earthquake Survival Guide",
                category="Natural Disasters",
                icon_asset="assets/icons/earthquake.png",
                essential_steps=5,
                is_available_offline=True,
                steps=[
                    SurvivalStep(
                        order=1,
                        title="Drop, Cover, and Hold On",
                        description="Drop to your hands and knees. Cover your head and neck under a sturdy desk or table. Hold on until the shaking stops.",
                    ),
                    SurvivalStep(
                        order=2,
                        title="Stay Away from Windows",
                        description="Move away from windows, outside walls, and anything that could fall, such as lighting fixtures or furniture.",
                    ),
                    SurvivalStep(
                        order=3,
                        title="If Outdoors",
                        description="Move to a clear area away from buildings, trees, streetlights, and utility wires. Drop to the ground and stay there until shaking stops.",
                    ),
                    SurvivalStep(
                        order=4,
                        title="After the Earthquake",
                        description="Check yourself and others for injuries. Be prepared for aftershocks. Check for gas leaks and damage.",
                    ),
                    SurvivalStep(
                        order=5,
                        title="Emergency Supplies",
                        description="Keep an emergency kit with water, food, flashlight, first aid kit, and important documents ready.",
                    ),
                ],
                last_updated=datetime.now(),
            ),
            SurvivalGuide(
                id="flood_guide",
                title="Flood Survival Guide",
                category="Natural Disasters",
                icon_asset="assets/icons/flood.png",
                essential_steps=5,
                is_available_offline=True,
                steps=[
                    SurvivalStep(
                        order=1,
                        title="Move to Higher Ground",
                        description="If flooding is imminent, move immediately to higher ground. Do not wait for instructions to move.",
                    ),
                    SurvivalStep(
                        order=2,
                        title="Never Walk or Drive Through Flood Water",
                        description="Just 6 inches of moving water can knock you down. 2 feet of water can float a vehicle.",
                    ),
                    SurvivalStep(
                        order=3,
                        title="Turn Off Utilities",
                        description="If safe to do so, turn off utilities at the main switches or valves. Disconnect electrical appliances.",
                    ),
                    SurvivalStep(
                        order=4,
                        title="Stay Informed",
                        description="Listen to local radio or TV for updates. Follow evacuation orders immediately.",
                    ),
                    SurvivalStep(
                        order=5,
                        title="After the Flood",
                        description="Return only when authorities say it's safe. Clean and disinfect everything that got wet. Document damage for insurance.",
                    ),
                ],
                last_updated=datetime.now(),
            ),
            SurvivalGuide(
                id="thunderstorm_guide",
                title="Thunderstorm Safety Guide",
                category="Weather",
                icon_asset="assets/icons/storm.png",
                essential_steps=4,
                is_available_offline=True,
                steps=[
                    SurvivalStep(
                        order=1,
                        title="Seek Shelter Immediately",
                        description="Go indoors when you hear thunder. A substantial building or hard-topped vehicle is safest.",
                    ),
                    SurvivalStep(
                        order=2,
                        title="Stay Away from Windows",
                        description="Close windows and doors. Stay away from windows, doors, and electrical equipment.",
                    ),
                    SurvivalStep(
                        order=3,
                        title="Avoid Water and Metal",
                        description="Do not shower, bathe, or do dishes during a thunderstorm. Avoid contact with metal objects.",
                    ),
                    SurvivalStep(
                        order=4,
                        title="If Caught Outside",
                        description="Avoid tall objects, open fields, and water. Crouch low with feet together, minimizing ground contact.",
                    ),
                ],
                last_updated=datetime.now(),
            ),
            SurvivalGuide(
                id="first_aid_guide",
                title="Basic First Aid Guide",
                category="Emergency Response",
                icon_asset="assets/icons/first_aid.png",
                essential_steps=5,
                is_available_offline=True,
                steps=[
                    SurvivalStep(
                        order=1,
                        title="Assess the Situation",
                        description="Check for danger to yourself and the victim. Call emergency services if needed.",
                    ),
                    SurvivalStep(
                        order=2,
                        title="Check Responsiveness",
                        description="Tap the person's shoulder and ask loudly 'Are you okay?' Look for signs of breathing.",
                    ),
                    SurvivalStep(
                        order=3,
                        title="Control Bleeding",
                        description="Apply direct pressure with a clean cloth. Elevate the injured area if possible.",
                    ),
                    SurvivalStep(
                        order=4,
                        title="Treat for Shock",
                        description="Keep the person lying down and warm. Elevate legs if no spinal injury is suspected.",
                    ),
                    SurvivalStep(
                        order=5,
                        title="CPR Basics",
                        description="For adults: 30 chest compressions, 2 breaths. Continue until help arrives or the person recovers.",
                    ),
                ],
                last_updated=datetime.now(),
            ),
        ]


# Singleton instance
survival_guide_service = SurvivalGuideService()
