"""
AI Assistant service using Google Gemini
"""

from typing import Optional
from app.core.config import settings

try:
    import google.generativeai as genai
    GEMINI_AVAILABLE = True
except ImportError:
    GEMINI_AVAILABLE = False


class AIAssistantService:
    def __init__(self):
        self.model = None
        if GEMINI_AVAILABLE and settings.gemini_api_key:
            genai.configure(api_key=settings.gemini_api_key)
            self.model = genai.GenerativeModel("gemini-pro")

    async def get_safety_advice(
        self,
        disaster_type: str,
        user_location: Optional[str] = None,
        is_emergency: bool = False,
    ) -> str:
        """Get safety advice from AI for a specific disaster type"""
        if self.model is None:
            return self._get_offline_safety_advice(disaster_type)

        try:
            prompt = self._build_prompt(
                disaster_type=disaster_type,
                user_location=user_location,
                is_emergency=is_emergency,
            )
            response = self.model.generate_content(prompt)
            return response.text or self._get_offline_safety_advice(disaster_type)
        except Exception as e:
            print(f"AI Assistant error: {e}")
            return self._get_offline_safety_advice(disaster_type)

    async def chat(self, user_message: str) -> str:
        """Chat with AI assistant about disaster safety"""
        if self.model is None:
            return "AI Assistant is currently unavailable. Please check your configuration."

        try:
            prompt = f"""
You are GeoGuard's AI Safety Assistant. Your role is to provide helpful,
accurate information about disaster preparedness, safety procedures, and
emergency response. Be concise but thorough.

User question: {user_message}

Provide a helpful response focusing on safety and practical advice.
"""
            response = self.model.generate_content(prompt)
            return response.text or "I apologize, but I could not generate a response. Please try again."
        except Exception as e:
            print(f"AI Chat error: {e}")
            return "I apologize, but I am having trouble responding right now. Please try again later."

    async def get_precautions(self, disaster_type: str) -> str:
        """Get precautions for specific disaster"""
        if self.model is None:
            return self._get_offline_precautions(disaster_type)

        try:
            prompt = f"""
Provide a concise list of precautions for {disaster_type} safety.
Format as numbered steps. Be practical and actionable.
Keep the response under 200 words.
"""
            response = self.model.generate_content(prompt)
            return response.text or self._get_offline_precautions(disaster_type)
        except Exception as e:
            return self._get_offline_precautions(disaster_type)

    async def analyze_seasonal_trends(self, region: str, month: int) -> str:
        """Analyze seasonal disaster trends"""
        if self.model is None:
            return "Seasonal analysis requires AI service to be configured."

        try:
            month_name = self._get_month_name(month)
            prompt = f"""
Analyze the typical natural disaster patterns for {region} during {month_name}.
Include:
1. Most common disaster types
2. Historical frequency
3. Recommended preparations
Keep the response concise and practical.
"""
            response = self.model.generate_content(prompt)
            return response.text or "Unable to analyze seasonal trends at this time."
        except Exception as e:
            return "Unable to analyze seasonal trends at this time."

    def _build_prompt(
        self,
        disaster_type: str,
        user_location: Optional[str] = None,
        is_emergency: bool = False,
    ) -> str:
        if is_emergency:
            location_info = f" in {user_location}" if user_location else ""
            return f"""
EMERGENCY SITUATION: A user is experiencing a {disaster_type} event{location_info}.

Provide IMMEDIATE, life-saving instructions in a calm, clear manner.
Focus on:
1. Immediate actions to take RIGHT NOW
2. What to avoid
3. When to evacuate vs shelter in place

Be concise and prioritize the most critical actions first.
"""

        location_info = f" in {user_location}" if user_location else ""
        return f"""
A user wants to know about {disaster_type} safety{location_info}.

Provide practical safety advice including:
1. Before the event (preparation)
2. During the event
3. After the event

Keep the response helpful and under 300 words.
"""

    def _get_offline_safety_advice(self, disaster_type: str) -> str:
        disaster_type_lower = disaster_type.lower()

        if disaster_type_lower == "earthquake":
            return """
🏠 EARTHQUAKE SAFETY

DURING:
• DROP to hands and knees
• Take COVER under sturdy furniture
• HOLD ON until shaking stops
• Stay away from windows and heavy objects

AFTER:
• Check for injuries and provide first aid
• Be prepared for aftershocks
• Check gas, water, and electric lines
• Use flashlight, not candles
"""
        elif disaster_type_lower == "flood":
            return """
🌊 FLOOD SAFETY

DURING:
• Move immediately to higher ground
• Never walk or drive through flood waters
• Turn off utilities at main switches
• Disconnect electrical appliances

AFTER:
• Return only when authorities say it's safe
• Clean and disinfect everything
• Watch for road hazards
• Document damage for insurance
"""
        else:
            return """
⛈️ SEVERE WEATHER SAFETY

DURING:
• Go indoors immediately
• Stay away from windows
• Avoid using corded phones
• Unplug electronic equipment

IF CAUGHT OUTSIDE:
• Avoid tall isolated objects
• Get to low ground
• Never seek shelter under trees
"""

    def _get_offline_precautions(self, disaster_type: str) -> str:
        disaster_type_lower = disaster_type.lower()

        if disaster_type_lower == "earthquake":
            return """
1. Secure heavy furniture to walls
2. Know how to turn off utilities
3. Prepare an emergency kit
4. Identify safe spots in each room
5. Practice DROP, COVER, HOLD ON drills
"""
        elif disaster_type_lower == "flood":
            return """
1. Know your flood risk zone
2. Keep important documents elevated
3. Have a battery-powered radio
4. Never drive through flooded roads
5. Have evacuation routes planned
"""
        else:
            return """
1. Monitor weather forecasts
2. Have a battery-powered radio
3. Know your shelter location
4. Keep emergency supplies ready
5. Have a family communication plan
"""

    def _get_month_name(self, month: int) -> str:
        months = [
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December"
        ]
        return months[(month - 1) % 12]


# Singleton instance
ai_assistant_service = AIAssistantService()
