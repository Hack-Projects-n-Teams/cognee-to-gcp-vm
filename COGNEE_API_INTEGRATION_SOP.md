# Cognee API Integration SOP

**Purpose:** Connect existing application services to Cognee VM for semantic search and knowledge management.

**Prerequisites:**
- Cognee VM running and accessible (from VM Setup SOP)
- Application backend/frontend code access
- API documentation familiarity

**Scope:** Integration patterns for backend services to interact with Cognee API.

---

## Environment Configuration

### Backend Configuration

Add to your application's environment variables:

```env
# .env file in your main application
COGNEE_BASE_URL=http://YOUR_COGNEE_VM_IP:8000
COGNEE_API_KEY=  # Usually not required for basic endpoints
COGNEE_TIMEOUT=30
```

Example:
```env
COGNEE_BASE_URL=http://34.102.136.180:8000
COGNEE_TIMEOUT=30
```

### Client Library Setup

```python
# Python example
import os
from cognics import CogneeClient

# Initialize Cognee client
client = CogneeClient(
    base_url=os.getenv("COGNEE_BASE_URL"),
    timeout=int(os.getenv("COGNEE_TIMEOUT", 30))
)
```

```javascript
// Node.js example
const { CogneeClient } = require('cognee-sdk');

const client = new CogneeClient({
  baseURL: process.env.COGNEE_BASE_URL,
  timeout: parseInt(process.env.COGNEE_TIMEOUT) || 30000,
});
```

---

## Core API Operations

### 1. Health Check Integration

**Purpose:** Verify Cognee connectivity before operations.

```python
# Python health check
import requests

def check_cognee_health():
    try:
        response = requests.get(f"{os.getenv('COGNEE_BASE_URL')}/health", timeout=10)
        data = response.json()
        return data.get('status') == 'ready'
    except Exception as e:
        logger.error(f"Cognee health check failed: {e}")
        return False

# Use before operations
if not check_cognee_health():
    raise Exception("Cognee service unavailable")
```

### 2. Content Ingestion

**Purpose:** Add documents/content to Cognee's knowledge base.

```python
# Python content ingestion
from cognics import CogneeClient

async def ingest_document(content: str, metadata: dict = None):
    """Ingest content into Cognee knowledge base"""
    client = CogneeClient(base_url=os.getenv("COGNEE_BASE_URL"))

    result = await client.ingest(
        content=content,
        metadata=metadata or {},
        content_type="text/plain"
    )
    return result

# Usage
content = "Your document content here..."
metadata = {"source": "user_upload", "category": "documentation"}
await ingest_document(content, metadata)
```

```javascript
// JavaScript content ingestion
async function ingestDocument(content, metadata = {}) {
  const client = new CogneeClient({
    baseURL: process.env.COGNEE_BASE_URL
  });

  try {
    const result = await client.ingest({
      content: content,
      metadata: {
        ...metadata,
        ingested_at: new Date().toISOString()
      },
      contentType: 'text/plain'
    });
    return result;
  } catch (error) {
    console.error('Ingestion failed:', error);
    throw error;
  }
}

// Usage
const content = "Your document content...";
const metadata = { source: "web_scraping", category: "news" };
await ingestDocument(content, metadata);
```

### 3. Semantic Search

**Purpose:** Query Cognee for semantically similar content.

```python
# Python semantic search
from cognics import CogneeClient
import asyncio

async def semantic_search(query: str, limit: int = 10):
    """Search for semantically similar content"""
    client = CogneeClient(base_url=os.getenv("COGNEE_BASE_URL"))

    results = await client.search(
        query=query,
        limit=limit,
        search_type="semantic"
    )

    return [
        {
            "content": hit.content,
            "score": hit.score,
            "metadata": hit.metadata
        }
        for hit in results.hits
    ]

# Usage
results = await semantic_search("machine learning algorithms", limit=5)
```

```javascript
// JavaScript semantic search
async function semanticSearch(query, limit = 10) {
  const client = new CogneeClient({
    baseURL: process.env.COGNEE_BASE_URL
  });

  try {
    const response = await client.search({
      query: query,
      limit: limit,
      searchType: 'semantic'
    });

    return response.hits.map(hit => ({
      content: hit.content,
      score: hit.score,
      metadata: hit.metadata
    }));
  } catch (error) {
    console.error('Search failed:', error);
    throw error;
  }
}

// Usage
const results = await semanticSearch("quantum computing", 5);
console.log(results);
```

### 4. Knowledge Graph Operations

**Purpose:** Traverse and query knowledge relationships.

```python
# Python knowledge graph
from cognics import CogneeClient

async def query_knowledge_graph(node_id: str, relationship_type: str = None):
    """Query knowledge graph relationships"""
    client = CogneeClient(base_url=os.getenv("COGNEE_BASE_URL"))

    # Get related concepts
    related = await client.graph.traverse(
        start_node=node_id,
        relationship_type=relationship_type or "related_to",
        max_depth=3
    )

    return related
```

### 5. Batch Operations

**Purpose:** Handle multiple documents efficiently.

```python
# Python batch ingestion
from cognics import CogneeClient
from typing import List, Dict
import asyncio

async def batch_ingest(documents: List[Dict]):
    """Ingest multiple documents efficiently"""
    client = CogneeClient(base_url=os.getenv("COGNEE_BASE_URL"))

    tasks = []
    for doc in documents:
        task = client.ingest(
            content=doc["content"],
            metadata=doc.get("metadata", {}),
            content_type=doc.get("content_type", "text/plain")
        )
        tasks.append(task)

    # Execute in parallel with concurrency limit
    results = []
    semaphore = asyncio.Semaphore(5)  # Max 5 concurrent requests

    async def limited_ingest(task):
        async with semaphore:
            return await task

    results = await asyncio.gather(*[limited_ingest(task) for task in tasks])
    return results
```

---

## Error Handling Patterns

### Network Issues

```python
# Python robust error handling
from cognics import CogneeClient
import tenacity
from tenacity import retry, stop_after_attempt, wait_exponential

class CogneeService:
    def __init__(self):
        self.client = CogneeClient(
            base_url=os.getenv("COGNEE_BASE_URL"),
            timeout=30
        )

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=4, max=10),
        retry=tenacity.retry_if_exception_type((ConnectionError, TimeoutError))
    )
    async def safe_ingest(self, content: str):
        """Safe ingestion with automatic retries"""
        try:
            result = await self.client.ingest(content=content)
            return result
        except ConnectionError:
            logger.warning("Cognee connection failed, retrying...")
            raise
        except Exception as e:
            logger.error(f"Cognee ingestion failed: {e}")
            raise
```

### Circuit Breaker Pattern

```python
# Python circuit breaker
import asyncio
import time

class CogneeCircuitBreaker:
    def __init__(self, failure_threshold=5, recovery_timeout=60):
        self.failures = 0
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.last_failure = 0
        self.state = "CLOSED"  # CLOSED, OPEN, HALF_OPEN

    async def call(self, operation):
        if self.state == "OPEN":
            if time.time() - self.last_failure > self.recovery_timeout:
                self.state = "HALF_OPEN"
            else:
                raise Exception("Circuit breaker is OPEN")

        try:
            result = await operation()
            self._on_success()
            return result
        except Exception as e:
            self._on_failure()
            raise e

    def _on_success(self):
        self.failures = 0
        self.state = "CLOSED"

    def _on_failure(self):
        self.failures += 1
        self.last_failure = time.time()
        if self.failures >= self.failure_threshold:
            self.state = "OPEN"
```

---

## Monitoring and Observability

### Health Checks in Application

```python
# Python application health checks
from fastapi import FastAPI, HTTPException
import httpx

app = FastAPI()

@app.get("/health")
async def health_check():
    """Application health check that includes Cognee"""
    checks = {
        "database": await check_database(),
        "cognee": await check_cognee()
    }

    if not all(checks.values()):
        raise HTTPException(status_code=503, detail=checks)

    return checks

async def check_cognee():
    """Verify Cognee availability"""
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            response = await client.get(f"{os.getenv('COGNEE_BASE_URL')}/health")
            data = response.json()
            return data.get("status") == "ready"
    except Exception:
        return False
```

### Metrics Collection

```python
# Python Prometheus metrics
from prometheus_client import Counter, Histogram, Gauge

# Cognee operation metrics
COGNEE_REQUESTS = Counter('cognee_requests_total', 'Total Cognee requests', ['operation', 'status'])
COGNEE_LATENCY = Histogram('cognee_request_duration_seconds', 'Cognee request latency', ['operation'])
COGNEE_CONNECTION_STATUS = Gauge('cognee_service_up', 'Cognee service availability')

class MetricsCogneeClient:
    """Cognee client with metrics collection"""

    def __init__(self, client):
        self.client = client

    async def search(self, query, **kwargs):
        with COGNEE_LATENCY.labels(operation='search').time():
            try:
                result = await self.client.search(query, **kwargs)
                COGNEE_REQUESTS.labels(operation='search', status='success').inc()
                COGNEE_CONNECTION_STATUS.set(1)
                return result
            except Exception as e:
                COGNEE_REQUESTS.labels(operation='search', status='error').inc()
                COGNEE_CONNECTION_STATUS.set(0)
                raise e
```

---

## Best Practices

### 1. Connection Management

```python
# Python connection pooling
from cognics import CogneeClient

# Singleton client pattern
class CogneeConnectionPool:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = CogneeClient(
                base_url=os.getenv("COGNEE_BASE_URL"),
                max_keepalive_connections=20,
                max_connections=100
            )
        return cls._instance

# Usage
cognee = CogneeConnectionPool()
```

### 2. Content Preprocessing

```python
# Python content preparation
import re
from typing import Optional

def preprocess_content(content: str, source: str) -> dict:
    """Prepare content for Cognee ingestion"""
    # Remove excessive whitespace
    content = re.sub(r'\s+', ' ', content.strip())

    # Extract metadata
    metadata = {
        "source": source,
        "ingested_at": datetime.utcnow().isoformat(),
        "word_count": len(content.split()),
        "size_bytes": len(content.encode('utf-8'))
    }

    # Chunk large content if needed
    if len(content) > 50000:  # 50KB limit example
        chunks = _chunk_content(content, max_size=45000)
        return {"chunks": chunks, "metadata": metadata}

    return {"content": content, "metadata": metadata}
```

### 3. Caching and Rate Limiting

```python
# Python Redis caching for Cognee results
import redis
import hashlib

class CogneeCache:
    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client
        self.ttl = 3600  # 1 hour

    def get_cache_key(self, query: str) -> str:
        return f"cognee:search:{hashlib.md5(query.encode()).hexdigest()}"

    async def cached_search(self, query: str, limit: int = 10):
        """Search with Redis caching"""
        cache_key = self.get_cache_key(query)

        # Check cache
        cached = self.redis.get(cache_key)
        if cached:
            return json.loads(cached)

        # Perform search
        results = await cognics_client.search(query, limit=limit)

        # Cache results
        self.redis.setex(cache_key, self.ttl, json.dumps(results))

        return results
```

### 4. Graceful Degradation

```python
# Python fallback when Cognee is unavailable
class GracefulCogneeClient:
    """Client that falls back gracefully when Cognee is down"""

    def __init__(self, primary_client, fallback_search=None):
        self.primary = primary_client
        self.fallback = fallback_search  # e.g., simple text search

    async def search(self, query: str, **kwargs):
        try:
            return await self.primary.search(query, **kwargs)
        except Exception as e:
            logger.warning(f"Cognee search failed, falling back: {e}")
            if self.fallback:
                return await self.fallback.search(query, **kwargs)
            else:
                # Return empty results or basic handling
                return {"hits": [], "fallback": True}
```

---

## Migration Path

### From Local to VM Deployment

```python
# Before (local Cognee)
client = CogneeClient(base_url="http://localhost:8000")

# After (VM deployment)
client = CogneeClient(base_url="http://YOUR_VM_EXTERNAL_IP:8000")

# Environment variable approach
client = CogneeClient(base_url=os.getenv("COGNEE_BASE_URL"))
```

### Incremental Rollout

1. **Feature Flag Approach:**
```python
# Enable Cognee features gradually
ENABLE_COGNEE_SEARCH = os.getenv("ENABLE_COGNEE_SEARCH", "false").lower() == "true"

if ENABLE_COGNEE_SEARCH:
    results = await cognee_client.search(query)
else:
    results = await traditional_search(query)
```

2. **Shadow Testing:**
```python
# Test Cognee alongside existing search
async def dual_search(query):
    """Compare results from both systems"""
    traditional_results = await traditional_search(query)

    try:
        cognee_results = await cognee_client.search(query)
        # Log comparison metrics
        compare_search_quality(traditional_results, cognee_results)
        return cognee_results
    except Exception:
        return traditional_results
```

---

## Security Considerations

### API Key Management

```python
# Environment-based secrets
import os
from cognics import CogneeClient

# Server-side key rotation
class SecureCogneeClient:
    def __init__(self):
        self.api_keys = self._load_keys_from_vault()

    def _load_keys_from_vault(self):
        # Load from AWS Secrets Manager, HashiCorp Vault, etc.
        return {
            "primary": os.getenv("COGNEE_API_KEY_1"),
            "secondary": os.getenv("COGNEE_API_KEY_2")
        }

    async def get_client(self):
        """Get client with current valid key"""
        for key_name, key in self.api_keys.items():
            # Test key validity
            if await self._test_key(key):
                return CogneeClient(api_key=key)
        raise Exception("No valid Cognee API keys available")
```

### Request Encryption

```python
# Python HTTPS enforcement
import ssl
from cognics import CogneeClient

# Force HTTPS
ssl_context = ssl.create_default_context()
ssl_context.check_hostname = True
ssl_context.verify_mode = ssl.CERT_REQUIRED

client = CogneeClient(
    base_url="https://your-cognee-vm.com:8000",
    ssl_context=ssl_context
)
```

---

## Performance Optimization

### Connection Pooling

```python
# Python aiohttp session reuse
import aiohttp
from cognics import CogneeClient

class PooledCogneeClient:
    def __init__(self):
        self.session = aiohttp.ClientSession(
            connector=aiohttp.TCPConnector(limit=100, ttl_dns_cache=30),
            timeout=aiohttp.ClientTimeout(total=60)
        )
        self.client = CogneeClient(
            base_url=os.getenv("COGNEE_BASE_URL"),
            session=self.session
        )

    async def close(self):
        await self.session.close()
```

### Query Optimization

```python
# Python query caching and deduplication
from functools import lru_cache
import asyncio
import hashlib

class OptimizedCogneeClient:
    def __init__(self, client):
        self.client = client
        self.cache = {}
        self.cache_ttl = 300  # 5 minutes

    @lru_cache(maxsize=1000)
    def _query_hash(self, query: str, limit: int) -> str:
        """Generate consistent hash for caching"""
        return hashlib.md5(f"{query}:{limit}".encode()).hexdigest()

    async def optimized_search(self, query: str, limit: int = 10):
        """Search with caching and deduplication"""
        query_hash = self._query_hash(query, limit)

        # Check cache
        if query_hash in self.cache:
            cached_time, cached_result = self.cache[query_hash]
            if time.time() - cached_time < self.cache_ttl:
                return cached_result

        # Perform search
        result = await self.client.search(query, limit=limit)

        # Update cache
        self.cache[query_hash] = (time.time(), result)

        return result
```

---

## Troubleshooting Integration

### Common Integration Issues

```python
# Python connectivity debugging
import requests
import time

def debug_cognee_connection():
    """Comprehensive connectivity test"""
    base_url = os.getenv("COGNEE_BASE_URL")

    tests = [
        ("Basic connectivity", f"{base_url}/health"),
        ("API responsiveness", f"{base_url}/status"),
        ("QDrant proxy", f"{base_url}/qdrant/collections")
    ]

    for test_name, url in tests:
        try:
            start = time.time()
            response = requests.get(url, timeout=10)
            latency = time.time() - start

            print(f"✅ {test_name}: {response.status_code} in {latency:.2f}s")

            if response.status_code != 200:
                print(f"   Response: {response.text[:200]}...")

        except requests.exceptions.Timeout:
            print(f"❌ {test_name}: Timeout (>10s)")
        except requests.exceptions.ConnectionError:
            print(f"❌ {test_name}: Connection failed")
        except Exception as e:
            print(f"❌ {test_name}: {type(e).__name__}: {e}")

debug_cognee_connection()
