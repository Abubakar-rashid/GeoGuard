"""
AI Assistant service using Hugging Face
"""

from typing import Optional
import httpx
from app.core.config import settings

try:
    from huggingface_hub import InferenceClient
    HUGGINGFACE_AVAILABLE = True
except ImportError:
    HUGGINGFACE_AVAILABLE = False


class AIAssistantService:
    def __init__(self):
        self.client = None
        # Use chat-capable model, configurable via .env
        # Example: OpenAssistant/replit-code-v1-3b (if available) or another provider-backed model.
        self.model_id = settings.huggingface_model_id or "OpenAssistant/replit-code-v1-3b"

        if HUGGINGFACE_AVAILABLE and settings.huggingface_api_token:
            self.client = InferenceClient(
                token=settings.huggingface_api_token
            )

    async def _generate_response(self, prompt: str) -> Optional[str]:
        """Generate response using Hugging Face or Gemini as fallback."""
        # First attempt Hugging Face, if configured
        if self.client is not None:
            try:
                messages = [
                    {"role": "system", "content": "You are GeoGuard's AI Safety Assistant. Provide helpful, accurate information about disaster preparedness, safety procedures, and emergency response. Be concise but thorough."},
                    {"role": "user", "content": prompt}
                ]
                hf_response = self.client.chat_completion(
                    model=self.model_id,
                    messages=messages,
                    max_tokens=500,
                    temperature=0.7,
                )
                # Try content first, then reasoning as fallback (some HF chat models use reasoning field)
                message_obj = hf_response.choices[0].message
                chat_text = getattr(message_obj, 'content', None)
                if chat_text and str(chat_text).strip():
                    return str(chat_text).strip()
                reasoning_text = getattr(message_obj, 'reasoning', None)
                if reasoning_text and str(reasoning_text).strip():
                    return str(reasoning_text).strip()
                # If response includes an 'output' or direct text
                if hasattr(hf_response, 'output') and hf_response.output:
                    return str(hf_response.output).strip()
            except Exception as e:
                print(f"Hugging Face API chat_completion error: {e}")

            try:
                fallback_response = self.client.text_generation(
                    model=self.model_id,
                    prompt=prompt,
                    max_new_tokens=300,
                    temperature=0.7,
                )
                if isinstance(fallback_response, str):
                    return fallback_response.strip()
                generated = getattr(fallback_response, 'generated_text', None)
                if generated and str(generated).strip():
                    return str(generated).strip()
                if isinstance(fallback_response, dict):
                    candidate = fallback_response.get('generated_text') or fallback_response.get('text')
                    if candidate:
                        return str(candidate).strip()
            except Exception as e:
                print(f"Hugging Face API text_generation error: {e}")

        # If HF fails, try Gemini (text generation endpoint)
        if settings.gemini_api_key:
            try:
                gemini_url = f"https://generativelanguage.googleapis.com/v1beta2/models/{settings.gemini_model_id}:generate"
                response = httpx.post(
                    gemini_url,
                    params={"key": settings.gemini_api_key},
                    json={
                        "prompt": {
                            "text": prompt
                        },
                        "temperature": 0.7,
                        "maxOutputTokens": 300
                    },
                    timeout=30,
                )
                if response.status_code == 200:
                    data = response.json()
                    candidate = None
                    if "candidates" in data and data["candidates"]:
                        candidate = data["candidates"][0].get("output")
                    if not candidate:
                        candidate = data.get("output") or data.get("text")
                    if candidate:
                        return str(candidate).strip()
                else:
                    print(f"Gemini API returned status {response.status_code}: {response.text}")
            except Exception as e:
                print(f"Gemini API error: {e}")

        return None

    async def get_safety_advice(
        self,
        disaster_type: str,
        user_location: Optional[str] = None,
        is_emergency: bool = False,
    ) -> str:
        """Get safety advice from AI for a specific disaster type"""
        if self.client is None:
            return self._get_offline_safety_advice(disaster_type)

        try:
            prompt = self._build_prompt(
                disaster_type=disaster_type,
                user_location=user_location,
                is_emergency=is_emergency,
            )
            response = await self._generate_response(prompt)
            return response or self._get_offline_safety_advice(disaster_type)
        except Exception as e:
            print(f"AI Assistant error: {e}")
            return self._get_offline_safety_advice(disaster_type)

    async def chat(self, user_message: str) -> str:
        """Chat with AI assistant about disaster safety"""
        if self.client is None:
            return "AI Assistant is currently unavailable. Please check your configuration."

        try:
            prompt = f"""
You are GeoGuard's AI Safety Assistant. Your role is to provide helpful,
accurate information about disaster preparedness, safety procedures, and
emergency response. Be concise but thorough.

User question: {user_message}

Provide a helpful response focusing on safety and practical advice.
"""
            response = await self._generate_response(prompt)
            return response or "I apologize, but I could not generate a response. Please try again."
        except Exception as e:
            print(f"AI Chat error: {e}")
            return "I apologize, but I am having trouble responding right now. Please try again later."

    async def get_precautions(self, disaster_type: str) -> str:
        """Get precautions for specific disaster"""
        if self.client is None:
            return self._get_offline_precautions(disaster_type)

        try:
            prompt = f"""
Provide a concise list of precautions for {disaster_type} safety.
Format as numbered steps. Be practical and actionable.
Keep the response under 200 words.
"""
            response = await self._generate_response(prompt)
            return response or self._get_offline_precautions(disaster_type)
        except Exception as e:
            return self._get_offline_precautions(disaster_type)

    async def analyze_seasonal_trends(self, region: str, month: int) -> str:
        """Analyze seasonal disaster trends"""
        if self.client is None:
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
            response = await self._generate_response(prompt)
            return response or "Unable to analyze seasonal trends at this time."
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
