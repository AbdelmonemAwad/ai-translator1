"""
Media Services Integration for AI Translator
تكامل خدمات الوسائط للترجمان الآلي
"""

import requests
import logging
from typing import Dict, List, Optional, Any
import json

logger = logging.getLogger(__name__)

class MediaServicesManager:
    """Unified manager for all media services"""
    
    def __init__(self):
        self.services = {}
        self.active_services = []
    
    def register_service(self, service_name: str, service_instance):
        """Register a media service"""
        self.services[service_name] = service_instance
        logger.info(f"Registered media service: {service_name}")
    
    def get_service(self, service_name: str):
        """Get a specific service instance"""
        return self.services.get(service_name)
    
    def test_all_services(self) -> Dict[str, bool]:
        """Test connectivity to all registered services"""
        results = {}
        for name, service in self.services.items():
            try:
                results[name] = service.test_connection()
            except Exception as e:
                logger.error(f"Error testing {name}: {e}")
                results[name] = False
        return results

class PlexMediaServer:
    """Plex Media Server integration"""
    
    def __init__(self, url: str, token: str):
        self.url = url.rstrip('/')
        self.token = token
        self.headers = {'X-Plex-Token': token}
    
    def test_connection(self) -> bool:
        """Test Plex server connection"""
        try:
            response = requests.get(f"{self.url}/status/sessions", 
                                  headers=self.headers, timeout=10)
            return response.status_code == 200
        except Exception as e:
            logger.error(f"Plex connection error: {e}")
            return False
    
    def get_libraries(self) -> List[Dict]:
        """Get Plex libraries"""
        try:
            response = requests.get(f"{self.url}/library/sections", 
                                  headers=self.headers, timeout=10)
            if response.status_code == 200:
                return response.json().get('MediaContainer', {}).get('Directory', [])
            return []
        except Exception as e:
            logger.error(f"Error getting Plex libraries: {e}")
            return []

class JellyfinServer:
    """Jellyfin Server integration"""
    
    def __init__(self, url: str, api_key: str):
        self.url = url.rstrip('/')
        self.api_key = api_key
        self.headers = {'X-Emby-Authorization': f'MediaBrowser Token={api_key}'}
    
    def test_connection(self) -> bool:
        """Test Jellyfin server connection"""
        try:
            response = requests.get(f"{self.url}/System/Info", 
                                  headers=self.headers, timeout=10)
            return response.status_code == 200
        except Exception as e:
            logger.error(f"Jellyfin connection error: {e}")
            return False
    
    def get_libraries(self) -> List[Dict]:
        """Get Jellyfin libraries"""
        try:
            response = requests.get(f"{self.url}/Library/VirtualFolders", 
                                  headers=self.headers, timeout=10)
            if response.status_code == 200:
                return response.json()
            return []
        except Exception as e:
            logger.error(f"Error getting Jellyfin libraries: {e}")
            return []

class RadarrAPI:
    """Radarr API integration for movie management"""
    
    def __init__(self, url: str, api_key: str):
        self.url = url.rstrip('/')
        self.api_key = api_key
        self.headers = {'X-Api-Key': api_key}
    
    def test_connection(self) -> bool:
        """Test Radarr connection"""
        try:
            response = requests.get(f"{self.url}/api/v3/system/status", 
                                  headers=self.headers, timeout=10)
            return response.status_code == 200
        except Exception as e:
            logger.error(f"Radarr connection error: {e}")
            return False
    
    def get_movies(self) -> List[Dict]:
        """Get movies from Radarr"""
        try:
            response = requests.get(f"{self.url}/api/v3/movie", 
                                  headers=self.headers, timeout=30)
            if response.status_code == 200:
                return response.json()
            return []
        except Exception as e:
            logger.error(f"Error getting Radarr movies: {e}")
            return []
    
    def get_quality_profiles(self) -> List[Dict]:
        """Get quality profiles from Radarr"""
        try:
            response = requests.get(f"{self.url}/api/v3/qualityprofile", 
                                  headers=self.headers, timeout=10)
            
            # تحقق من نوع المحتوى المُستلم
            content_type = response.headers.get('content-type', '').lower()
            
            if response.status_code == 200:
                # إذا كان المحتوى HTML بدلاً من JSON، فهذا خطأ مصادقة
                if 'text/html' in content_type or response.text.strip().startswith('<!doctype'):
                    logger.error("Radarr returned HTML instead of JSON - likely authentication error")
                    return []
                
                try:
                    profiles = response.json()
                    return [{'id': p['id'], 'name': p['name']} for p in profiles]
                except json.JSONDecodeError as json_err:
                    logger.error(f"Radarr returned invalid JSON: {json_err}")
                    logger.error(f"Response content: {response.text[:200]}")
                    return []
            
            elif response.status_code == 401:
                logger.error("Radarr authentication failed - check API key")
                return []
            elif response.status_code == 404:
                logger.error("Radarr API endpoint not found - check URL")
                return []
            else:
                logger.error(f"Radarr API error: {response.status_code} - {response.text[:200]}")
                return []
                
        except requests.exceptions.ConnectTimeout:
            logger.error("Connection timeout to Radarr - check if service is running")
            return []
        except requests.exceptions.ConnectionError as conn_err:
            logger.error(f"Connection error to Radarr: {conn_err}")
            return []
        except Exception as e:
            logger.error(f"Unexpected error getting Radarr quality profiles: {e}")
            return []

class SonarrAPI:
    """Sonarr API integration for TV series management"""
    
    def __init__(self, url: str, api_key: str):
        self.url = url.rstrip('/')
        self.api_key = api_key
        self.headers = {'X-Api-Key': api_key}
    
    def test_connection(self) -> bool:
        """Test Sonarr connection"""
        try:
            response = requests.get(f"{self.url}/api/v3/system/status", 
                                  headers=self.headers, timeout=10)
            return response.status_code == 200
        except Exception as e:
            logger.error(f"Sonarr connection error: {e}")
            return False
    
    def get_series(self) -> List[Dict]:
        """Get TV series from Sonarr"""
        try:
            response = requests.get(f"{self.url}/api/v3/series", 
                                  headers=self.headers, timeout=30)
            if response.status_code == 200:
                return response.json()
            return []
        except Exception as e:
            logger.error(f"Error getting Sonarr series: {e}")
            return []
    
    def get_quality_profiles(self) -> List[Dict]:
        """Get quality profiles from Sonarr"""
        try:
            response = requests.get(f"{self.url}/api/v3/qualityprofile", 
                                  headers=self.headers, timeout=10)
            
            # تحقق من نوع المحتوى المُستلم
            content_type = response.headers.get('content-type', '').lower()
            
            if response.status_code == 200:
                # إذا كان المحتوى HTML بدلاً من JSON، فهذا خطأ مصادقة
                if 'text/html' in content_type or response.text.strip().startswith('<!doctype'):
                    logger.error("Sonarr returned HTML instead of JSON - likely authentication error")
                    return []
                
                try:
                    profiles = response.json()
                    return [{'id': p['id'], 'name': p['name']} for p in profiles]
                except json.JSONDecodeError as json_err:
                    logger.error(f"Sonarr returned invalid JSON: {json_err}")
                    logger.error(f"Response content: {response.text[:200]}")
                    return []
            
            elif response.status_code == 401:
                logger.error("Sonarr authentication failed - check API key")
                return []
            elif response.status_code == 404:
                logger.error("Sonarr API endpoint not found - check URL")
                return []
            else:
                logger.error(f"Sonarr API error: {response.status_code} - {response.text[:200]}")
                return []
                
        except requests.exceptions.ConnectTimeout:
            logger.error("Connection timeout to Sonarr - check if service is running")
            return []
        except requests.exceptions.ConnectionError as conn_err:
            logger.error(f"Connection error to Sonarr: {conn_err}")
            return []
        except Exception as e:
            logger.error(f"Unexpected error getting Sonarr quality profiles: {e}")
            return []

def create_media_services_manager() -> MediaServicesManager:
    """Create and configure media services manager"""
    manager = MediaServicesManager()
    
    # Services will be configured from database settings
    logger.info("Media services manager created")
    
    return manager