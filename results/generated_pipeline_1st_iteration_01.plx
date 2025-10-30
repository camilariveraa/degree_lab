domain = "homework_solving"
description = "Solving homework problems from photos with step-by-step solutions and study resources"
main_pipe = "homework_solver_sequence"

[concept.HomeworkPhoto]
description = "A photo of homework content"
refines = "Image"

[concept.HomeworkAnalysis]
description = "Structured extraction of homework content from a photo"

[concept.HomeworkAnalysis.structure]
extracted_text = { type = "text", description = "All text content extracted from the homework photo", required = true }
subject_area = { type = "text", description = "The academic subject area identified (e.g., math, science, history)", required = true }
raw_questions_list = { type = "text", description = "List of all questions or problems found in the homework", required = true }
visual_elements_description = { type = "text", description = "Description of any diagrams, charts, or visual elements present", required = false }

[concept.StructuredQuestion]
description = "A parsed individual question with metadata"

[concept.StructuredQuestion.structure]
question_number = { type = "text", description = "The assigned number or identifier for the question", required = true }
question_text = { type = "text", description = "The full text of the question or problem", required = true }
subject = { type = "text", description = "The subject area for this specific question", required = true }
difficulty_level = { type = "text", description = "Estimated difficulty level of the question", required = true }

[concept.QuestionSolution]
description = "Comprehensive solution for a single question"

[concept.QuestionSolution.structure]
question_number = { type = "text", description = "The question number this solution corresponds to", required = true }
step_by_step_reasoning = { type = "text", description = "Detailed reasoning for each step of the solution", required = true }
calculations = { type = "text", description = "All mathematical calculations shown", required = false }
explanations = { type = "text", description = "Clear explanations in simple language", required = true }
final_answer = { type = "text", description = "The final answer to the question, highlighted", required = true }
concept_explanation = { type = "text", description = "Additional explanation of underlying concepts", required = false }
memory_tips = { type = "text", description = "Helpful tips to remember the concept or approach", required = false }

[concept.HomeworkSolutionsDocument]
description = "Complete compiled homework solutions document"

[concept.HomeworkSolutionsDocument.structure]
subject = { type = "text", description = "The primary subject area of the homework", required = true }
total_questions = { type = "integer", description = "Total count of questions solved", required = true }
organized_solutions = { type = "text", description = "All solutions organized and formatted", required = true }
study_notes = { type = "text", description = "General study notes for the topic", required = false }
recommended_resources = { type = "text", description = "Recommended learning resources including YouTube channels and websites", required = false }

[pipe.homework_solver_sequence]
type = "PipeSequence"
description = """
Main orchestrator for the complete homework solving workflow that extracts content from a homework photo, structures questions, solves them in detail, and compiles a final comprehensive solutions document
"""
inputs = { homework_photo = "HomeworkPhoto" }
output = "HomeworkSolutionsDocument"
steps = [
    { pipe = "extract_homework_content", result = "homework_analysis" },
    { pipe = "structure_questions", result = "structured_questions" },
    { pipe = "solve_all_questions_batch", result = "question_solutions" },
    { pipe = "compile_final_document", result = "homework_solutions_document" },
]

[pipe.extract_homework_content]
type = "PipeLLM"
description = """
Analyze the homework photo using vision AI to extract all text, identify subject area, list questions, and describe visual elements
"""
inputs = { homework_photo = "HomeworkPhoto" }
output = "HomeworkAnalysis"
model = "llm_for_visual_analysis"
system_prompt = """
You are an expert at analyzing homework photos and extracting structured information. Your task is to carefully examine the image and produce a structured HomeworkAnalysis object.
"""
prompt = """
Analyze this homework photo and extract all relevant information:

$homework_photo

Please carefully examine the image and identify:
- All text content visible in the homework
- The academic subject area (e.g., mathematics, science, history, etc.)
- All questions or problems present
- Any diagrams, charts, graphs, or other visual elements
"""

[pipe.structure_questions]
type = "PipeLLM"
description = """
Parse the extracted homework content into individual structured questions with metadata including question number, subject, and difficulty level
"""
inputs = { homework_analysis = "HomeworkAnalysis" }
output = "StructuredQuestion[]"
model = "llm_to_answer_easy_questions"
system_prompt = """
You are a homework analysis assistant. Your task is to parse extracted homework content and structure it into individual questions with metadata. You will generate a structured list of questions.
"""
prompt = """
Parse the following homework analysis into individual structured questions.

@homework_analysis

For each question or problem identified in the homework:
- Assign a clear question number or identifier
- Extract the complete question text
- Identify the specific subject area
- Estimate the difficulty level (e.g., easy, medium, hard)

Generate a structured list of all questions found in the homework.
"""

[pipe.solve_all_questions_batch]
type = "PipeBatch"
description = """
Apply the solution process to each structured question concurrently to generate comprehensive solutions
"""
inputs = { structured_questions = "StructuredQuestion[]", homework_analysis = "HomeworkAnalysis" }
output = "QuestionSolution[]"
branch_pipe_code = "solve_single_question"
input_list_name = "structured_questions"
input_item_name = "structured_question"

[pipe.solve_single_question]
type = "PipeLLM"
description = """
Generate a comprehensive step-by-step solution for a single question including reasoning, calculations, explanations, final answer, concept explanation, and memory tips
"""
inputs = { structured_question = "StructuredQuestion", homework_analysis = "HomeworkAnalysis" }
output = "QuestionSolution"
model = "llm_to_answer_hard_questions"
system_prompt = """
You are an expert tutor who provides comprehensive, step-by-step solutions to homework questions. Your goal is to help students understand not just the answer, but the reasoning and concepts behind it. You will generate a structured solution for the given question.
"""
prompt = """
You are solving a homework question from the subject area: $structured_question.subject

Here is the question to solve:

Question #$structured_question.question_number
Subject: $structured_question.subject
Difficulty: $structured_question.difficulty_level
Question: $structured_question.question_text

Context from the homework:
@homework_analysis.extracted_text

Provide a comprehensive solution for this question. Show all your work, explain your reasoning clearly, and help the student understand the underlying concepts.
"""

[pipe.compile_final_document]
type = "PipeLLM"
description = """
Compile all solutions into a complete homework solutions document with subject identification, question count, organized solutions, study notes, and recommended learning resources
"""
inputs = { homework_analysis = "HomeworkAnalysis", structured_questions = "StructuredQuestion[]", question_solutions = "QuestionSolution[]" }
output = "HomeworkSolutionsDocument"
model = "llm_to_answer_easy_questions"
system_prompt = """
You are a homework solutions compiler. Your task is to create a comprehensive, well-organized homework solutions document from the provided analysis, questions, and solutions. Generate a structured HomeworkSolutionsDocument object.
"""
prompt = """
Compile a complete homework solutions document based on the following information:

@homework_analysis

@structured_questions

@question_solutions

Create a comprehensive document that includes:
- The primary subject area
- Total count of questions
- All solutions organized in a clear, easy-to-follow format
- General study notes that help understand the overall topic
- Recommended learning resources (YouTube channels, websites, etc.) for further study
"""
