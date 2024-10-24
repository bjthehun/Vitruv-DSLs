package tools.vitruv.dsls.reactions.builder

import org.hamcrest.TypeSafeMatcher
import org.hamcrest.Description
import org.eclipse.xtext.testing.util.ParseHelper
import tools.vitruv.dsls.reactions.language.toplevelelements.ReactionsFile
import tools.vitruv.dsls.reactions.api.generator.IReactionsGenerator
import org.eclipse.xtext.generator.InMemoryFileSystemAccess
import com.google.inject.Inject
import com.google.inject.Provider
import org.eclipse.xtext.resource.XtextResourceSet
import java.util.function.Consumer
import java.io.InputStreamReader
import com.google.common.io.CharStreams
import org.eclipse.emf.common.util.URI
import org.hamcrest.Matcher
import java.util.Map

/**
 * A matcher checking reactions generated by a
 * {@link FluentReactionsFileBuilder}. See {@link #builds} for details.
 */
class GeneratedReactionsMatcherBuilder {
	static val SYNTHETIC = URI.createHierarchicalURI("synthetic", null, null, #[], null, null)

	@Inject var ParseHelper<ReactionsFile> parseHelper
	@Inject var Provider<IReactionsGenerator> generatorProvider
	@Inject var Provider<InMemoryFileSystemAccess> inMemoryFileSystemAccessProvider
	@Inject Provider<XtextResourceSet> resourceSetProvider

	static class GeneratedReactionsMatcher extends TypeSafeMatcher<FluentReactionsFileBuilder> {
		val extension GeneratedReactionsMatcherBuilder generatedReactions
		val String expectedReaction
		var Consumer<Description> mismatch

		new(GeneratedReactionsMatcherBuilder generatedReactions, String expectedReaction) {
			this.generatedReactions = generatedReactions
			this.expectedReaction = expectedReaction
		}

		override protected matchesSafely(FluentReactionsFileBuilder item) {
			val generator = generatorProvider.get()
			val fsa = inMemoryFileSystemAccessProvider.get()
			generator.useResourceSet(resourceSetProvider.get())
			generator.addReactionsFile(item)
			generator.writeReactions(fsa)

			if (!fsa.hasSingleGeneratedFile) {
				return false
			}
			val serializationResult = fsa.singleGeneratedFileContent
			if (!expectedReaction.isEqual(serializationResult)) {
				return false
			}

			val expectedGeneratedCodeFileNamesToContents = expectedReaction.generateCodeFiles
			val actualGeneratedCodeFileNamesToContents = serializationResult.generateCodeFiles

			return expectedGeneratedCodeFileNamesToContents.areEqual(actualGeneratedCodeFileNamesToContents)
		}

		private def hasSingleGeneratedFile(InMemoryFileSystemAccess fsa) {
			if (fsa.allFiles.size !== 1) {
				if (fsa.allFiles.size === 0) {
					mismatch = [appendText('serializing the builder had no results')]
				} else {
					mismatch = [
						appendText('serializing the builder had more than one result: ').appendValueList('[', ', ', ']',
							fsa.allFiles.keySet)
					]
				}
				return false
			}
			return true
		}

		private def String getSingleGeneratedFileContent(InMemoryFileSystemAccess fsa) {
			return fsa.read(fsa.allFiles.keySet.head)
		}

		private def boolean isEqual(String expectedReactionsCode, String generatedReactionsCode) {
			if (!expectedReactionsCode.equalsIgnoringWhitespace(generatedReactionsCode)) {
				mismatch = [
					appendText('serializing the builder resulted in a different reactions file:\n\n').appendText(
						generatedReactionsCode).appendText('\n\nFirst mismatching line:\n\n').appendValue(
						firstMismatchLineIgnoringWhitespace(generatedReactionsCode, expectedReactionsCode))
				]
				return false
			}
			return true
		}

		private def Map<String, CharSequence> generateCodeFiles(String reactionsCode) {
			val resourceSet = resourceSetProvider.get()
			parseHelper.parse(reactionsCode, SYNTHETIC.appendSegment("reaction").appendFileExtension('reactions'),
				resourceSet)
			val fsa = inMemoryFileSystemAccessProvider.get()
			val generator = generatorProvider.get()
			generator.addReactionsFiles(resourceSet)
			generator.generate(fsa)
			return fsa.textFiles
		}

		private def boolean areEqual(Map<String, CharSequence> expectedGeneratedCodeFileNamesToContents,
			Map<String, CharSequence> actualGeneratedCodeFileNamesToContents) {
			val unexpectedItemFile = actualGeneratedCodeFileNamesToContents.keySet.findFirst [
				!expectedGeneratedCodeFileNamesToContents.containsKey(it)
			]
			if (unexpectedItemFile !== null) {
				mismatch = [
					appendText('generating from the builder produced the unexpected file ').appendValue(
						unexpectedItemFile)
				]
				return false
			}
			val missingItemFile = expectedGeneratedCodeFileNamesToContents.keySet.findFirst [
				!actualGeneratedCodeFileNamesToContents.containsKey(it)
			]
			if (missingItemFile !== null) {
				mismatch = [
					appendText('generating from the builder did not produce the expected file ').appendValue(
						missingItemFile)
				]
			}
			for (filePath : expectedGeneratedCodeFileNamesToContents.keySet) {
				val expectedContent = expectedGeneratedCodeFileNamesToContents.get(filePath).toString
				val itemContent = actualGeneratedCodeFileNamesToContents.get(filePath).toString
				if (!expectedContent.equalsIgnoringWhitespace(itemContent)) {
					mismatch = [
						appendText('generating from the builder produced wrong content for ').appendValue(filePath).
							appendText('.\nExpected was:\n\n').appendText(expectedContent).appendText(
								'\n\n But got:\n\n').appendText(itemContent).appendText(
								'\n\nFirst mismatching line:\n\n').appendValue(
								firstMismatchLineIgnoringWhitespace(itemContent, expectedContent))
					]
					return false
				}
			}
			return true
		}

		override describeTo(Description description) {
			description.appendText("a reactions file builder producing this reactions file: \n\n").appendText(
				expectedReaction)
		}

		override protected describeMismatchSafely(FluentReactionsFileBuilder item, Description mismatchDescription) {
			mismatch?.accept(mismatchDescription)
		}

	}

	/**
	 * Created a matcher for a {@link FluentReactionsFileBuilder}. The matcher
	 * checks that the builder builds the given {@code expectedReaction}. It
	 * does this in two ways: By comparing the serialized builder result with
	 * the {@code expectedReaction}, and by generating Java code for both and
	 * comparing that code.
	 * 
	 * <p>The reaction code is compared ignoring whitespace, the generated Java
	 * code is compared character by character.
	 */
	def Matcher<? super FluentReactionsFileBuilder> builds(String expectedReaction) {
		new GeneratedReactionsMatcher(this, expectedReaction)
	}

	/**
	 * Tries to build the provided {@code builder}, without any further checks.
	 */
	def build(FluentReactionsFileBuilder builder) {
		val generator = generatorProvider.get()
		val fsa = inMemoryFileSystemAccessProvider.get()
		generator.useResourceSet(resourceSetProvider.get())
		generator.addReactionsFile(builder)
		generator.generate(fsa)
	}

	def private read(InMemoryFileSystemAccess fsa, String path) {
		CharStreams.toString(new InputStreamReader(fsa.readBinaryFile(path, '')))
	}

	def private static withoutWhitespace(String s) {
		return s.replaceAll("\\s+", "")
	}

	def private static equalsIgnoringWhitespace(String a, String b) {
		a.withoutWhitespace.equals(b.withoutWhitespace)
	}

	def private static firstMismatchLineIgnoringWhitespace(String mismatch, String reference) {
		val mismatchLines = mismatch.split(System.lineSeparator)
		val unmatchingLineInMismatch = mismatchLines.getFirstLineNotContainedInReferenceText(reference)
		if (unmatchingLineInMismatch !== null) {
			return unmatchingLineInMismatch
		} else {
			val referenceLines = reference.split(System.lineSeparator)
			return referenceLines.getFirstLineNotContainedInReferenceText(mismatch)
		}
	}
	
	def private static getFirstLineNotContainedInReferenceText(String[] lines, String reference) {
		val referenceWithoutWhitespace = reference.withoutWhitespace
		return lines.findFirst[!referenceWithoutWhitespace.contains(it.withoutWhitespace)]
	}

}
