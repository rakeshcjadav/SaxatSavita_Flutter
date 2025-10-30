# Multi-Word Search with Relevance Scoring

## Overview
Enhanced the `_performSearch` method in `kiransearchpage.dart` to support flexible multi-word searching with intelligent relevance-based sorting.

## Relevance Scoring System

### Scoring Algorithm
The `_calculateRelevanceScore` method uses a sophisticated scoring system:

#### 1. Exact Matches (Score: 100)
- Perfect match: "Rakesh Jadav" = "Rakesh Jadav" → **100 points**

#### 2. Exact Phrase Matches (Score: 80-105)
- Contains exact phrase: "Rakesh Jadav" in "Rakesh Jadavbhai" → **80-105 points**
- **Bonuses:**
  - Starts with query: +15 points
  - Whole word boundaries: +10 points

#### 3. Multi-Word Matches (Score: 0-95)
- All words present: "Rakesh Jadav" in "Rakesh Chhaganbhai Jadav" → **Variable score**
- **Per-word scoring:**
  - Base word match: +20 points
  - Word at beginning: +10 points
  - Whole word match: +5 points
  - Words close together (≤20 chars): +3 points
- **Multipliers:**
  - Match ratio: score × (matched_words / total_words)
  - All words matched: +15 bonus points
- **Penalties:**
  - Length penalty: -(text_length / 100) up to -10 points

### Expected Results Order

For query **"Rakesh Jadav"**:

1. **"Rakesh Jadav"** → Score: ~100 (exact match)
2. **"Rakesh Jadavbhai"** → Score: ~95 (exact phrase + bonuses)  
3. **"Rakeshbhai Jadav"** → Score: ~90 (exact phrase)
4. **"Rakesh Chhaganbhai Jadav"** → Score: ~75 (multi-word, close proximity)
5. **"Rakesh Kumar"** → Score: ~25 (partial match, 1 of 2 words)
6. **"Something Jadav"** → Score: ~25 (partial match, 1 of 2 words)

### Implementation Details

#### Title vs Content Scoring
- **Title matches**: Base relevance + 10 bonus points
- **Content matches**: Base relevance score only
- Title matches are prioritized in results

#### Sorting Logic
1. **Primary**: Relevance score (highest first)
2. **Secondary**: Title matches before content matches
3. **Tertiary**: Kiran index order

## Multi-Word Matching Logic

### `_matchesMultiWord(String text, String query)`
- Splits query into individual words
- Checks if ALL words exist in text (case-insensitive)
- Words can appear in any order and position

### `_highlightMultiWordMatch(String text, String query)`
- Highlights each matching word with `**word**` markers
- Supports non-adjacent word highlighting
- Case-insensitive matching with original case preserved

## Search Flow
1. **Title Search**: Check for multi-word matches in title + number
2. **Content Search**: Search within kiran content files
3. **Relevance Calculation**: Score each match using algorithm
4. **Sorting**: Order by relevance score (highest first)
5. **Highlighting**: Apply multi-word highlighting

## Examples

### Query: "Swami Narayan"
**Results (ordered by relevance):**
1. "Swami Narayan" → **95+ points**
2. "Swami Shree Narayan" → **85+ points** 
3. "Narayan Swami" → **75+ points**
4. "Bhagwan Swami Narayan Bhagwan" → **70+ points**

### Query: "Rakesh Jadav"
**Results (ordered by relevance):**
1. "Rakesh Jadav" → **~100 points**
2. "Rakesh Jadavbhai" → **~95 points**
3. "Rakeshbhai Jadav" → **~90 points**
4. "Rakesh Chhaganbhai Jadav" → **~75 points**
5. "Rakesh Kumar" → **~25 points**
6. "Something Jadav" → **~25 points**

## Benefits
- **Intelligent Ranking**: Most relevant results appear first
- **Flexible Matching**: Finds content even with word variations
- **Context Awareness**: Considers word proximity and positioning
- **User-Friendly**: Better search experience with predictable ordering
- **Backward Compatibility**: Maintains exact phrase search support