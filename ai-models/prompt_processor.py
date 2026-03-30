# prompt_processor.py

"""
This module contains a prompt processor for DJ prompts utilizing BERT for NLP, intent extraction, and a versatile query builder.
"""

from transformers import BertTokenizer, BertForSequenceClassification
import torch

class PromptProcessor:
    def __init__(self):
        self.tokenizer = BertTokenizer.from_pretrained('bert-base-uncased')
        self.model = BertForSequenceClassification.from_pretrained('bert-base-uncased')

    def process_prompt(self, prompt):
        tokens = self.tokenizer(prompt, return_tensors='pt')
        with torch.no_grad():
            outputs = self.model(**tokens)
        logits = outputs.logits
        return torch.argmax(logits, dim=-1).item()

    def query_builder(self, intent):
        # Builds a query based on the intent
        return f"What would you like to do related to {intent}?"

    def extract_intent(self, prompt):
        # Intent extraction logic here
        return 'music'  # Example placeholder

