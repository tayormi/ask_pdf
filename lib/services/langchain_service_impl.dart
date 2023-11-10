import 'package:ask_pdf/core/config.dart';
import 'package:ask_pdf/services/langchain_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:langchain_pinecone/langchain_pinecone.dart';
import 'package:pinecone/pinecone.dart';

final langchainServiceProvider = Provider<LangChainService>((ref) {
  final pineConeApiKey = dotenv.env['PINECONE_API_KEY']!;
  final environment = dotenv.env['PINECONE_ENVIRONMENT']!;
  final openAIApiKey = dotenv.env['OPENAI_API_KEY']!;

  final pineconeClient = PineconeClient(
    apiKey: pineConeApiKey,
    baseUrl: 'https://controller.$environment.pinecone.io',
  );

  final embeddings = OpenAIEmbeddings(
    apiKey: openAIApiKey,
  );

  final langchainPinecone = Pinecone(
    apiKey: pineConeApiKey,
    indexName: ServiceConfig.indexName,
    embeddings: embeddings,
    environment: environment,
  );

  final llm = OpenAI(apiKey: openAIApiKey, maxTokens: 500);

  final pineconeRetriever = VectorStoreRetriever(
    vectorStore: langchainPinecone,
    searchType: VectorStoreSearchType.similarity(k: 10),
  );

  final retrievalQAChain = RetrievalQAChain.fromLlm(
    llm: llm,
    retriever: pineconeRetriever,
  );

  return LangchainServiceImpl(
    client: pineconeClient,
    langchainPinecone: langchainPinecone,
    retrievalQAChain: retrievalQAChain,
  );
});

class LangchainServiceImpl implements LangChainService {
  final PineconeClient client;
  final Pinecone langchainPinecone;
  final RetrievalQAChain retrievalQAChain;

  LangchainServiceImpl({
    required this.client,
    required this.langchainPinecone,
    required this.retrievalQAChain,
  });

  @override
  Future<void> createPineConeIndex(
      String indexName, int vectorDimension) async {
    print("Checking $indexName");
    final indexes = await client.listIndexes();
    try {
      if (!indexes.contains(indexName)) {
        print("Creating $indexName ...");
        await client.createIndex(
          environment: dotenv.env['PINECONE_ENVIRONMENT']!,
          request: CreateIndexRequest(
            name: indexName,
            dimension: vectorDimension,
            metric: SearchMetric.cosine,
          ),
        );
        print('Creating index.... please wait for it to finish initializing.');
        // await Future.delayed(const Duration(seconds: 5));
      } else {
        print("$indexName already exists");
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Future<String> queryPineConeVectorStore(
      String indexName, String query) async {
    try {
      final result = await retrievalQAChain.invoke({
        RetrievalQAChain.defaultInputKey: 'What did I say?',
      });
      final answer = result[RetrievalQAChain.defaultOutputKey];
      print('Answer: $answer');
      return answer;
    } catch (e) {
      print(e);
      throw Exception('Error querying pinecone index');
    }
  }

  @override
  Future<void> updatePineConeIndex(
      String indexname, List<Document> docs) async {
    try {
      print('Updating ${docs.length} documents...');
      await langchainPinecone.addDocuments(documents: docs);
      print('Done updating documents');
    } catch (e) {
      print(e);
    }
  }
}
